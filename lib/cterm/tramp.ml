let ( let* ) = Result.bind
module Slots = Set.Make (struct type t = Cterm.slot let compare = compare end)

let atom = function Cterm.ALocal s -> Slots.singleton s
  | Cterm.AGlobal _ | Cterm.ALit _ | Cterm.AErased -> Slots.empty
let atoms xs = List.fold_left (fun set a -> Slots.union set (atom a)) Slots.empty xs
let rhs = function
  | Cterm.RAtom a | Cterm.RProj (a, _) -> atom a
  | Cterm.RMkClo (_, xs) | Cterm.RMkKont (_, xs) | Cterm.RMkCon (_, xs)
  | Cterm.RPrim (_, xs) | Cterm.RSyscall (_, xs) | Cterm.RCallKnown (_, xs) -> atoms xs
  | Cterm.RApply (f, a) -> Slots.union (atom f) (atom a)
let rec free (b : Cterm.block) =
  let tail = match b.tail with
    | Cterm.TRet a -> atom a
    | Cterm.TApply (f, a) | Cterm.TResume (f, a) -> Slots.union (atom f) (atom a)
    | Cterm.TSwitch (a, branches, default) -> List.fold_left (fun set (_, b) -> Slots.union set (free b)) (Slots.union (atom a) (free default)) branches
    | Cterm.TTrap Cterm.Trap_impossible_ctor -> Slots.empty in
  List.fold_right (fun (s, r) set -> Slots.union (rhs r) (Slots.remove s set)) b.binds tail

let rec all_slots (b : Cterm.block) =
  let base = List.fold_left (fun set (s, r) -> Slots.add s (Slots.union set (rhs r))) (free b) b.binds in
  match b.tail with
  | Cterm.TSwitch (_, branches, default) -> List.fold_left (fun set (_, b) -> Slots.union set (all_slots b)) (Slots.union base (all_slots default)) branches
  | Cterm.TRet _ | Cterm.TApply _ | Cterm.TResume _ | Cterm.TTrap _ -> base

let program (p : Cterm.program) =
  let konts = ref (Array.to_list p.konts) in
  let sources = ref (Array.to_list p.codes) in
  let adapters = ref [] in
  let max_slot (c : Cterm.code) =
    let set = List.fold_left (fun set s -> Slots.add s set) (all_slots c.body) (c.parameters @ c.capture_slots) in
    Slots.fold (fun s n -> max n (Cterm.slot_index s)) set (-1) in
  let counter = ref (-1) in
  let fresh () =
    if !counter = max_int then Error (Cerror.Cerr_slot_overflow (Cerror.diagnostic "trampoline" "continuation local overflow")) else
    (incr counter; Cterm.slot !counter |> Option.to_result ~none:(Cerror.Cerr_open_term (Cerror.diagnostic "trampoline" "negative local"))) in
  let tail_target tag (target : Cterm.code) =
    if target.arity = 1 then Ok tag else
    Option.fold ~none:(fun () ->
      match List.rev target.parameters with
      | [] -> Error (Cerror.Cerr_arity (Cerror.diagnostic target.name "tail target has no argument"))
      | last :: earlier ->
          let adapter, next = Cterm.append_code !sources
            ~name:("$tail." ^ target.name) ~kind:Cterm.Closure
            ~parameters:[last] ~capture_slots:(List.rev earlier) ~body:target.body in
          sources := next;
          adapters := (tag, adapter) :: !adapters;
          Ok adapter)
      ~some:(fun adapter () -> Ok adapter) (List.assoc_opt tag !adapters) ()
  in
  let tail_alias result rest tail =
    let rec aliases env = function
      | [] -> (match tail with
          | Cterm.TRet a ->
              let a = match a with Cterm.ALocal s -> Option.value (List.assoc_opt s env) ~default:a
                | Cterm.AGlobal _ | Cterm.ALit _ | Cterm.AErased -> a in
              a = Cterm.ALocal result
          | Cterm.TApply _ | Cterm.TResume _ | Cterm.TSwitch _ | Cterm.TTrap _ -> false)
      | (s, Cterm.RAtom a) :: rest ->
          let a = match a with Cterm.ALocal s -> Option.value (List.assoc_opt s env) ~default:a
            | Cterm.AGlobal _ | Cterm.ALit _ | Cterm.AErased -> a in aliases ((s, a) :: env) rest
      | (_, (Cterm.RMkClo _ | Cterm.RMkKont _ | Cterm.RMkCon _ | Cterm.RProj _
        | Cterm.RPrim _ | Cterm.RSyscall _ | Cterm.RCallKnown _ | Cterm.RApply _)) :: _ -> false in
    aliases [] rest
  in
  let rec block (b : Cterm.block) =
    let rec push before = function
      | [] -> let* tail = tail b.tail in Ok Cterm.{ binds = List.rev before; tail }
      | (result, Cterm.RCallKnown (tag, args)) :: rest
          when args <> [] && tail_alias result rest b.tail ->
          let* target = Cterm.code_of_tag p tag |> Option.to_result
            ~none:(Cerror.Cerr_unknown_global (Cerror.diagnostic "trampoline" "unknown tail target")) in
          let* () = if List.length args = target.arity then Ok () else
            Error (Cerror.Cerr_arity (Cerror.diagnostic target.name "tail call arity differs from target")) in
          let* adapter = tail_target tag target in
          (match List.rev args with
           | [] -> Error (Cerror.Cerr_arity (Cerror.diagnostic target.name "tail call has no argument"))
           | last :: earlier ->
               Ok Cterm.{ binds = List.rev before @ [result, RMkClo (adapter, List.rev earlier)];
                 tail = TApply (ALocal result, last) })
      | (result, Cterm.RApply (f, a)) :: rest ->
          if tail_alias result rest b.tail then Ok Cterm.{ binds = List.rev before; tail = TApply (f, a) } else
          let remainder = Cterm.{ binds = rest; tail = b.tail } in
          let captures = Slots.elements (Slots.remove result (free remainder)) in
          let* body = block remainder in
          let tag, next = Cterm.append_kont !konts ~capture_slots:captures ~result ~body in
          konts := next;
          let* pushed = fresh () in
          Ok Cterm.{ binds = List.rev before @ [pushed, RMkKont (tag, List.map (fun s -> ALocal s) captures)]; tail = TApply (f, a) }
      | bind :: rest -> push (bind :: before) rest
    in push [] b.binds
  and tail = function
    | Cterm.TSwitch (a, branches, default) ->
        let* branches = List.fold_left (fun acc (c, b) -> let* done_ = acc in let* b = block b in Ok (done_ @ [c, b])) (Ok []) branches in
        let* default = block default in Ok (Cterm.TSwitch (a, branches, default))
    | (Cterm.TRet _ | Cterm.TApply _ | Cterm.TResume _ | Cterm.TTrap _) as t -> Ok t
  in
  let rec compile index done_ =
    let next = List.to_seq !sources |> Seq.drop index |> Seq.uncons in
    (* The none branch is a thunk: an eager argument would rebuild the
       accumulator on every code, and only the last visit reads it. *)
    Option.fold ~none:(fun () -> Ok (List.rev done_))
      ~some:(fun ((c : Cterm.code), _) () ->
        counter := max_slot c;
        let* body = block c.body in
        compile (index + 1) ({ c with body } :: done_)) next () in
  let* codes = compile 0 [] in
  Ok { p with codes = Array.of_list codes; konts = Array.of_list !konts }
