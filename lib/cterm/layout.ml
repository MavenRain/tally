open Cterm

let ( let* ) = Result.bind
let error name detail = Error (Cerror.Cerr_arena_over (Cerror.diagnostic name detail))

let add name left right =
  if left < 0 || right < 0 || left > max_int - right then
    error name "layout size does not fit an OCaml integer"
  else Ok (left + right)

type measure = { high : int; words : int; literals : string list }
let empty = { high = 0; words = 0; literals = [] }

let join name left right =
  let* words = add name left.words right.words in
  Ok { high = max left.high right.high; words;
       literals = left.literals @ right.literals }

let local name slot =
  let* high = add name (slot_index slot) 1 in
  Ok { empty with high }

let atom name = function
  | ALocal slot -> local name slot
  | ALit (LStr text) -> Ok { empty with literals = [text] }
  | AGlobal _ | ALit (LInt _) | ALit (LWord _) | AErased -> Ok empty

let fold_measure name measure values =
  List.fold_left (fun result value ->
    let* total = result in
    let* next = measure value in
    join name total next) (Ok empty) values

let rhs name rhs =
  let atoms, header = match rhs with
    | RAtom value -> [value], 0
    | RMkClo (_, values) | RMkCon (_, values) -> values, 1
    | RMkKont (_, values) -> values, 2
    | RProj (value, _) -> [value], 0
    | RPrim (_, values) | RSyscall (_, values) | RCallKnown (_, values) -> values, 0
    | RApply (callee, argument) -> [callee; argument], 0 in
  let* measured = fold_measure name (atom name) atoms in
  let* words =
    if header = 0 then Ok 0 else add name header (List.length atoms) in
  Ok { measured with words }

let rec block name body =
  let* binds = fold_measure name (fun (slot, value) ->
    let* destination = local name slot in
    let* value = rhs name value in
    join name destination value) body.binds in
  let* ending = match body.tail with
    | TRet value -> atom name value
    | TApply (callee, argument) | TResume (callee, argument) ->
        fold_measure name (atom name) [callee; argument]
    | TTrap Trap_impossible_ctor -> Ok empty
    | TSwitch (scrutinee, arms, default) ->
        let* scrutinee = atom name scrutinee in
        let* branches = List.fold_left (fun result branch ->
          let* total = result in
          let* next = block name branch in
          Ok { high = max total.high next.high;
               words = max total.words next.words;
               literals = total.literals @ next.literals })
          (Ok empty) (List.map snd arms @ [default]) in
        join name scrutinee branches in
  join name binds ending

module Strings = Set.Make (String)

let string_layout literals =
  let* _, _, entries, pieces = List.fold_left (fun result text ->
    let* seen, offset, entries, pieces = result in
    if Strings.mem text seen then Ok (seen, offset, entries, pieces)
    else
      let length = String.length text in
      let* next = add "<program>" offset length in
      if next > Sys.max_string_length then error "<program>" "read-only strings exceed the host string capacity"
      else Ok (Strings.add text seen, next, (text, offset, length) :: entries, text :: pieces))
    (Ok (Strings.empty, 0, [], [])) literals in
  Ok (String.concat "" (List.rev pieces), List.rev entries)

let program ?arena_limit p =
  let* () = Option.fold ~none:(Ok ()) ~some:(fun limit ->
    if limit < 0 then error "<program>" "arena limit must be nonnegative" else Ok ()) arena_limit in
  let* codes, measured = Array.fold_left (fun result code ->
    let* codes, total = result in
    let* inputs = fold_measure code.name (local code.name)
      (code.parameters @ code.capture_slots) in
    let* body = block code.name code.body in
    let* own = join code.name inputs body in
    let* total = join "<program>" total own in
    Ok ({ code with frame_slots = own.high } :: codes, total)) (Ok ([], empty)) p.codes in
  (* This is one visit to each code and continuation, with the largest
     branch at a switch. Dynamic trampoline iterations are not bounded
     by this static footprint. A continuation includes its previous link. *)
  let* measured = Array.fold_left (fun result kont ->
    let* total = result in
    let name = "<kont " ^ string_of_int (kont_index kont.kont_id) ^ ">" in
    let* body = block name kont.kont_body in
    join "<program>" total body) (Ok measured) p.konts in
  let* () = Option.fold ~none:(Ok ()) ~some:(fun limit ->
    if measured.words > limit then
      error "<program>" (Printf.sprintf "arena footprint %d words exceeds caller limit %d" measured.words limit)
    else Ok ()) arena_limit in
  let* rodata, strings = string_layout measured.literals in
  Ok { p with codes = Array.of_list (List.rev codes);
       arena_words = measured.words; rodata; strings }
