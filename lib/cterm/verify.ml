open Cterm

let ( let* ) = Result.bind
let error name detail = Error (Cerror.Cerr_verify (Cerror.diagnostic name detail))
let require name condition detail = if condition then Ok () else error name detail
let each check values = List.fold_left (fun result value ->
  let* () = result in check value) (Ok ()) values

module Slots = Map.Make (Int)
module Strings = Set.Make (String)
type fact = Unknown | Constructor of ctor * int option | Closure_value of code_tag | Kont_value of kont_tag

let fact scope refinements value =
  let initial = match value with
    | ALocal slot -> Slots.find_opt (slot_index slot) scope |> Option.value ~default:Unknown
    | AGlobal ctor -> Constructor (ctor, Some 0)
    | ALit (LStr _) | ALit (LInt _) | ALit (LWord _) | AErased -> Unknown in
  List.assoc_opt value refinements |> Option.value ~default:initial

let slot_bound name frame slot =
  let index = slot_index slot in
  let* () = require name (index >= 0 && index < max_int) "invalid local slot index" in
  Option.fold ~none:(Ok ()) ~some:(fun count ->
    require name (index < count) "local slot exceeds the recorded frame") frame

let atom p name frame scope value =
  match value with
  | ALocal slot ->
      let* () = slot_bound name frame slot in
      require name (Slots.mem (slot_index slot) scope) "local slot is used before definition"
  | ALit (LStr text) ->
      require name (List.exists (fun (stored, _, _) -> String.equal stored text) p.strings)
        "string literal is missing from the read-only blob"
  | ALit (LInt _) -> Error (Cerror.Cerr_boxed_int (Cerror.diagnostic name "boxed integer in Cterm"))
  | AGlobal _ | ALit (LWord _) | AErased -> Ok ()

let primitive name prim =
  let open Tot_kernel in
  let diagnostic = Cerror.diagnostic name (Prim.name prim) in
  match prim with
  | Prim.Read_stdin | Prim.Print_line | Prim.Exit_with | Prim.Get_env
  | Prim.Read_file | Prim.Write_file | Prim.Argv | Prim.Proc_run -> Error (Cerror.Cerr_host_io diagnostic)
  | Prim.String_concat | Prim.String_length | Prim.String_eq | Prim.String_contains
  | Prim.String_slice | Prim.String_split | Prim.String_to_int | Prim.Int_to_string -> Error (Cerror.Cerr_host_string diagnostic)
  | Prim.Json_parse | Prim.Json_serialize -> Error (Cerror.Cerr_host_json diagnostic)
  | Prim.Regex_test | Prim.Regex_match -> Error (Cerror.Cerr_host_regex diagnostic)
  | Prim.Int_add | Prim.Int_sub | Prim.Int_eq | Prim.Int_compare -> Error (Cerror.Cerr_boxed_int diagnostic)
  | Prim.Pure_div | Prim.Bind_div | Prim.Pure_io | Prim.Bind_io | Prim.Lift_io -> Error (Cerror.Cerr_effect_prim diagnostic)
  | Prim.Word_add _ | Prim.Word_sub _ | Prim.Word_mul _ | Prim.Word_and _
  | Prim.Word_or _ | Prim.Word_xor _ | Prim.Word_not _ | Prim.Word_shl _
  | Prim.Word_eq _ | Prim.Word_div _ | Prim.Word_mod _ | Prim.Word_shr _
  | Prim.Word_compare _ | Prim.Word_to_string _ -> Ok ()

let code_target p name tag =
  code_of_tag p tag |> Option.to_result
    ~none:(Cerror.Cerr_verify (Cerror.diagnostic name "code tag is out of range"))

let kont_target p name tag =
  kont_of_tag p tag |> Option.to_result
    ~none:(Cerror.Cerr_verify (Cerror.diagnostic name "continuation tag is out of range"))

let rhs p name frame scope refinements rhs =
  let atoms = each (atom p name frame scope) in
  match rhs with
  | RAtom value -> let* () = atoms [value] in Ok (fact scope refinements value)
  | RMkClo (tag, captures) ->
      let* target = code_target p name tag in
      let* () = require name (target.arity = 1) "closure target must accept one argument" in
      let* () = require name (List.length captures = target.captures) "closure capture count differs from target" in
      let* () = atoms captures in Ok (Closure_value tag)
  | RMkKont (tag, captures) ->
      let* target = kont_target p name tag in
      let* () = require name (List.length captures = target.kont_captures) "continuation capture count differs from target" in
      let* () = atoms captures in Ok (Kont_value tag)
  | RMkCon (ctor, arguments) ->
      let* () = atoms arguments in Ok (Constructor (ctor, Some (List.length arguments)))
  | RProj (value, field) ->
      let* () = atoms [value] in
      let index = field_index field in
      let arity = field_arity field in
      let* () = require name (index >= 0 && index < arity) "projection field is outside its constructor arity" in
      let* () = match fact scope refinements value with
        | Constructor (_, count) -> Option.fold ~none:(Ok ()) ~some:(fun count ->
            require name (arity = count && index < count) "projection disagrees with the known constructor payload") count
        | Closure_value _ | Kont_value _ -> error name "projection requires a constructor value"
        | Unknown -> Ok () in
      Ok Unknown
  | RPrim (prim, arguments) ->
      let* () = primitive name prim in
      let* () = require name (List.length arguments = Tot_kernel.Prim.arity prim) "primitive call has the wrong arity" in
      let* () = atoms arguments in Ok Unknown
  | RSyscall (Syscall.Sol_log, arguments) ->
      let* () = require name (List.length arguments = 1) "logging syscall has the wrong arity" in
      let* () = atoms arguments in Ok Unknown
  | RCallKnown (tag, arguments) ->
      let* target = code_target p name tag in
      let* () = match target.kind with
        | Global -> require name (target.captures = 0) "direct global call requires a closed target"
        | Closure | Dispatch -> error name "direct call target is not a first-order global" in
      let* () = require name (List.length arguments = target.arity) "direct global call has the wrong arity" in
      let* () = atoms arguments in Ok Unknown
  | RApply (_, _) -> error name "intermediate application survived trampoline conversion"

let introduce name frame scope slot value =
  let* () = slot_bound name frame slot in
  let index = slot_index slot in
  let* () = require name (not (Slots.mem index scope)) "local slot is defined more than once" in
  Ok (Slots.add index value scope)

let rec block p name frame scope refinements body =
  let* scope = List.fold_left (fun result (slot, value) ->
    let* scope = result in
    let* value = rhs p name frame scope refinements value in
    introduce name frame scope slot value) (Ok scope) body.binds in
  let atoms = each (atom p name frame scope) in
  match body.tail with
  | TRet value -> atoms [value]
  | TApply (callee, argument) ->
      let* () = atoms [callee; argument] in
      let* () = match callee with
        | AErased | AGlobal _ | ALit (LStr _) | ALit (LInt _) | ALit (LWord _) ->
            error name "application has a statically non-closure callee"
        | ALocal _ -> Ok () in
      (match fact scope refinements callee with
       | Constructor _ | Kont_value _ -> error name "application has a statically non-closure callee"
       | Unknown | Closure_value _ -> Ok ())
  | TResume (continuation, value) ->
      let* () = atoms [continuation; value] in
      (match fact scope refinements continuation with
       | Constructor _ | Closure_value _ -> error name "resume target is not a continuation"
       | Unknown | Kont_value _ -> Ok ())
  | TTrap Trap_impossible_ctor -> Ok ()
  | TSwitch (scrutinee, branches, default) ->
      let* () = atoms [scrutinee] in
      let* () = require name (default.binds = []) "switch default must have no bindings" in
      let* () = match default.tail with
        | TTrap Trap_impossible_ctor -> Ok ()
        | TRet _ | TApply _ | TResume _ | TSwitch _ -> error name "switch default is not the impossible-constructor trap" in
      let* _ = List.fold_left (fun result (ctor, branch) ->
        let* seen = result in
        let label = ctor_name ctor in
        let* () = require name (not (Strings.mem label seen)) "switch repeats a constructor arm" in
        (* Check each arm under its own constructor fact. A known value
           selecting another arm cannot determine this arm's payload. *)
        let narrowed = match fact scope refinements scrutinee with
          | Constructor (known, count) when known = ctor -> Constructor (ctor, count)
          | Constructor _ | Unknown | Closure_value _ | Kont_value _ -> Constructor (ctor, None) in
        let* () = block p name frame scope ((scrutinee, narrowed) :: refinements) branch in
        Ok (Strings.add label seen)) (Ok Strings.empty) branches in
      block p name frame scope refinements default

let initial name frame slots =
  List.fold_left (fun result slot ->
    let* scope = result in introduce name frame scope slot Unknown)
    (Ok Slots.empty) slots

let strings p =
  let* _, offset = List.fold_left (fun result (text, offset, length) ->
    let* seen, expected = result in
    let* () = require "<program>" (not (Strings.mem text seen)) "read-only string is duplicated" in
    let* () = require "<program>" (length = String.length text && offset = expected)
      "read-only string offset or length is inconsistent" in
    let* () = require "<program>" (offset >= 0 && offset <= String.length p.rodata
      && length <= String.length p.rodata - offset) "read-only string range exceeds the blob" in
    let stored = String.to_seq p.rodata |> Seq.drop offset |> Seq.take length |> String.of_seq in
    let* () = require "<program>" (String.equal stored text) "read-only string contents differ from the blob" in
    Ok (Strings.add text seen, offset + length)) (Ok (Strings.empty, 0)) p.strings in
  require "<program>" (offset = String.length p.rodata) "read-only blob has extra bytes"

let program (p : Cterm.program) =
  let* _ = code_target p "<entry>" p.entry in
  let* () = require "<program>" (p.arena_words >= 0) "arena footprint is negative" in
  let* () = strings p in
  let* _ = Array.fold_left (fun result code ->
    let* index = result in
    let* () = require code.name (code_index code.code_id = index) "code tags are not dense" in
    let* () = require code.name (code.arity >= 0 && code.arity = List.length code.parameters)
      "code arity differs from its parameter slots" in
    let* () = require code.name (code.captures >= 0 && code.captures = List.length code.capture_slots)
      "code capture count differs from its capture slots" in
    let* () = require code.name (code.frame_slots >= 0) "code frame size is negative" in
    let* () = match code.kind with
      | Global -> require code.name (code.captures = 0) "global code has free captures"
      | Closure -> require code.name (code.arity = 1) "closure code is not unary"
      | Dispatch -> Ok () in
    let frame = Some code.frame_slots in
    let* scope = initial code.name frame (code.parameters @ code.capture_slots) in
    let* () = block p code.name frame scope [] code.body in
    Ok (index + 1)) (Ok 0) p.codes in
  let* _ = Array.fold_left (fun result kont ->
    let* index = result in
    let name = "<kont " ^ string_of_int index ^ ">" in
    let* () = require name (kont_index kont.kont_id = index) "continuation tags are not dense" in
    let* () = require name (kont.kont_captures >= 0 && kont.kont_captures = List.length kont.kont_capture_slots)
      "continuation capture count differs from its capture slots" in
    let* scope = initial name None (kont.kont_result :: kont.kont_capture_slots) in
    let* () = block p name None scope [] kont.kont_body in
    Ok (index + 1)) (Ok 0) p.konts in
  Ok ()

type counts = { dense : int; konts : int; switch_defaults : int; callknown_edges : int }

let rec block_counts body =
  let edges = List.fold_left (fun count (_, rhs) -> match rhs with
    | RCallKnown _ -> count + 1
    | RAtom _ | RMkClo _ | RMkKont _ | RMkCon _ | RProj _ | RPrim _ | RSyscall _ | RApply _ -> count)
    0 body.binds in
  match body.tail with
  | TRet _ | TApply _ | TResume _ | TTrap Trap_impossible_ctor -> 0, edges
  | TSwitch (_, branches, default) ->
      List.fold_left (fun (switches, edges) branch ->
        let more_switches, more_edges = block_counts branch in
        switches + more_switches, edges + more_edges)
        (1, edges) (List.map snd branches @ [default])

let summary (p : Cterm.program) =
  let add body (switches, edges) =
    let more_switches, more_edges = block_counts body in
    switches + more_switches, edges + more_edges in
  let code_counts = Array.fold_left (fun counts code -> add code.body counts) (0, 0) p.codes in
  let switch_defaults, callknown_edges =
    Array.fold_left (fun counts kont -> add kont.kont_body counts) code_counts p.konts in
  let _, dense = Array.fold_left (fun (index, count) code ->
    index + 1, count + (if code_index code.code_id = index then 1 else 0)) (0, 0) p.codes in
  let konts = Array.fold_left (fun count _ -> count + 1) 0 p.konts in
  { dense; konts; switch_defaults; callknown_edges }
