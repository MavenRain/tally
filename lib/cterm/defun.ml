let ( let* ) = Result.bind

let program (input : Clos.t) =
  let empty = Cterm.{ binds = []; tail = TTrap Trap_impossible_ctor } in
  let tags, reserved = List.fold_left (fun (tags, codes) (code : Clos.code) ->
    let tag, codes = Cterm.append_code codes ~name:code.name ~kind:code.kind
      ~parameters:code.parameters ~capture_slots:code.capture_slots ~body:empty in
    (code.name, tag) :: tags, codes) ([], []) input.codes in
  let tag name = List.assoc_opt name tags |> Option.to_result
    ~none:(Cerror.Cerr_unknown_global (Cerror.diagnostic name "missing closure code")) in
  let rhs = function
    | Clos.Atom a -> Ok (Cterm.RAtom a)
    | Clos.MkClo (name, captures) -> let* code = tag name in Ok (Cterm.RMkClo (code, captures))
    | Clos.MkCon (c, args) -> Ok (Cterm.RMkCon (c, args))
    | Clos.Proj (a, f) -> Ok (Cterm.RProj (a, f))
    | Clos.Prim (p, args) -> Ok (Cterm.RPrim (p, args))
    | Clos.CallKnown (name, args) -> let* code = tag name in Ok (Cterm.RCallKnown (code, args))
    | Clos.Apply (f, a) -> Ok (Cterm.RApply (f, a))
  in
  let rec block (b : Clos.block) =
    let* binds = List.fold_left (fun acc (s, r) ->
      let* done_ = acc in let* r = rhs r in Ok (done_ @ [s, r])) (Ok []) b.binds in
    let* tail = match b.tail with
      | Clos.Return a -> Ok (Cterm.TRet a)
      | Clos.Switch (a, branches) ->
          let* branches = List.fold_left (fun acc (c, b) ->
            let* done_ = acc in let* b = block b in Ok (done_ @ [c, b])) (Ok []) branches in
          Ok (Cterm.TSwitch (a, branches, empty)) in
    Ok Cterm.{ binds; tail }
  in
  let* codes = List.fold_left (fun acc (reserved : Cterm.code) ->
    let* done_ = acc in
    let* source = List.find_opt (fun (c : Clos.code) -> String.equal c.name reserved.name) input.codes
      |> Option.to_result ~none:(Cerror.Cerr_unknown_global (Cerror.diagnostic reserved.name "missing code body")) in
    let* body = block source.body in Ok (done_ @ [{ reserved with body }])) (Ok []) reserved in
  let* entry = tag input.root in
  Ok Cterm.{ codes = Array.of_list codes; konts = [||]; entry; arena_words = 0; rodata = ""; strings = [] }
