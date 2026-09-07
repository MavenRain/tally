open Tot_kernel
let ( let* ) = Result.bind
type rhs = Atom of Cterm.atom | MkClo of string * Cterm.atom list
  | MkCon of Cterm.ctor * Cterm.atom list | Proj of Cterm.atom * Cterm.field
  | Prim of Prim.t * Cterm.atom list | CallKnown of string * Cterm.atom list
  | Syscall of Cterm.Syscall.t * Cterm.atom list
  | Apply of Cterm.atom * Cterm.atom
type block = { binds : (Cterm.slot * rhs) list; tail : tail }
and tail = Return of Cterm.atom | Switch of Cterm.atom * (Cterm.ctor * block) list
type code = { name : string; kind : Cterm.code_kind; parameters : Cterm.slot list;
  capture_slots : Cterm.slot list; body : block }
type t = { root : string; codes : code list }

module Slots = Set.Make (struct type t = Cterm.slot let compare = compare end)
let locals = function Anf.Local s -> Slots.singleton s
  | Anf.Global _ | Anf.Lit _ | Anf.Erased -> Slots.empty
let rec free = function
  | Anf.Return a -> locals a
  | Anf.Let (s, rhs, body) -> Slots.union (free_rhs rhs) (Slots.remove s (free body))
  | Anf.Switch (a, branches) -> List.fold_left (fun acc (_, binders, b) ->
      Slots.union acc (List.fold_left (fun set s -> Slots.remove s set) (free b) binders)) (locals a) branches
and free_rhs = function
  | Anf.Atom a -> locals a
  | Anf.Apply (f, args) -> List.fold_left (fun s a -> Slots.union s (locals a)) (locals f) args
  | Anf.Lambda (s, body) -> Slots.remove s (free body)

let rec slots = function
  | Anf.Return a -> locals a
  | Anf.Let (s, rhs, b) -> Slots.add s (Slots.union (slots_rhs rhs) (slots b))
  | Anf.Switch (a, branches) -> List.fold_left (fun acc (_, binders, b) ->
      List.fold_left (fun set s -> Slots.add s set) (Slots.union acc (slots b)) binders) (locals a) branches
and slots_rhs = function
  | Anf.Atom a -> locals a
  | Anf.Apply (f, args) -> List.fold_left (fun s a -> Slots.union s (locals a)) (locals f) args
  | Anf.Lambda (s, b) -> Slots.add s (slots b)

let program (input : Anf.t) =
  let generated = ref [] in
  let wrappers = ref [] in
  let serial = ref 0 in
  let max_slot (d : Anf.definition) =
    let all = List.fold_left (fun set s -> Slots.add s set) (slots d.body) d.parameters in
    Slots.fold (fun s n -> max n (Cterm.slot_index s)) all (-1) in
  let counter = ref (-1) in
  let fresh () =
    if !counter = max_int then Error (Cerror.Cerr_slot_overflow (Cerror.diagnostic input.root "closure local overflow")) else
    (incr counter; Cterm.slot !counter |> Option.to_result ~none:(Cerror.Cerr_open_term (Cerror.diagnostic input.root "negative local")))
  in
  let symbol name = List.assoc_opt name input.symbols |> Option.to_result
    ~none:(Cerror.Cerr_unknown_global (Cerror.diagnostic name "uncollected global")) in
  let saturated name sym args = match sym with
    | Anf.Defined _ -> Ok (CallKnown (name, args))
    | Anf.Constructor _ -> Ok (MkCon (Cterm.ctor name, args))
    | Anf.Primitive p -> Ok (Prim (p, args))
    | Anf.Intrinsic syscall -> Ok (Syscall (syscall, args))
    | Anf.Erased_global -> Error (Cerror.Cerr_apply_erased (Cerror.diagnostic name "erased global application"))
  in
  let ensure_wrapper name sym arity =
    let first = "$curry." ^ name ^ ".0" in
    if List.mem name !wrappers then Ok first else
    let* params = List.fold_left (fun acc _ -> let* done_ = acc in let* s = fresh () in Ok (done_ @ [s])) (Ok []) (List.init arity Fun.id) in
    let rec build index captured = function
      | [] -> Ok ()
      | param :: rest ->
          let args = captured @ [param] in
          let* result = fresh () in
          let* rhs = match rest with
            | [] -> saturated name sym (List.map (fun s -> Cterm.ALocal s) args)
            | _ :: _ -> Ok (MkClo ("$curry." ^ name ^ "." ^ string_of_int (index + 1), List.map (fun s -> Cterm.ALocal s) args)) in
          let body = { binds = [result, rhs]; tail = Return (Cterm.ALocal result) } in
          let code = { name = "$curry." ^ name ^ "." ^ string_of_int index; kind = Cterm.Closure;
            parameters = [param]; capture_slots = captured; body } in
          generated := !generated @ [code]; build (index + 1) args rest
    in
    let* () = build 0 [] params in wrappers := name :: !wrappers; Ok first
  in
  let rec atom = function
    | Anf.Local s -> Ok ([], Cterm.ALocal s)
    | Anf.Lit l -> Ok ([], Cterm.ALit l)
    | Anf.Erased -> Ok ([], Cterm.AErased)
    | Anf.Global name ->
        let* sym = symbol name in
        let arity = match sym with Anf.Defined n | Anf.Constructor n -> n
          | Anf.Primitive p -> Prim.arity p | Anf.Intrinsic Cterm.Syscall.Sol_log -> 1
          | Anf.Erased_global -> 0 in
        if arity > 0 then
          let* code = ensure_wrapper name sym arity in
          let* s = fresh () in Ok ([s, MkClo (code, [])], Cterm.ALocal s)
        else match sym with
          | Anf.Constructor _ -> Ok ([], Cterm.AGlobal (Cterm.ctor name))
          | Anf.Erased_global -> Ok ([], Cterm.AErased)
          | Anf.Defined _ | Anf.Primitive _ | Anf.Intrinsic _ -> let* rhs = saturated name sym [] in
              let* s = fresh () in Ok ([s, rhs], Cterm.ALocal s)
  and atoms xs = List.fold_left (fun acc a ->
    let* binds, done_ = acc in let* before, a = atom a in
    Ok (binds @ before, done_ @ [a])) (Ok ([], [])) xs
  and unknown callee args =
    match args with
    | [] -> Ok ([], callee)
    | arg :: rest ->
        let* s = fresh () in
        let* binds, result = unknown (Cterm.ALocal s) rest in
        Ok ((s, Apply (callee, arg)) :: binds, result)
  and application head args =
    match head with
    | Anf.Global name ->
        let* sym = symbol name in
        let n = match sym with Anf.Defined n | Anf.Constructor n -> n
          | Anf.Primitive p -> Prim.arity p | Anf.Intrinsic Cterm.Syscall.Sol_log -> 1
          | Anf.Erased_global -> 0 in
        if List.length args >= n then
          let* binds, args = atoms args in
          let initial = List.filteri (fun i _ -> i < n) args in
          let rest = List.filteri (fun i _ -> i >= n) args in
          let* rhs = saturated name sym initial in let* s = fresh () in
          let* after, result = unknown (Cterm.ALocal s) rest in
          Ok (binds @ [s, rhs] @ after, result)
        else let* before, callee = atom head in let* binds, args = atoms args in
          let* after, result = unknown callee args in Ok (before @ binds @ after, result)
    | Anf.Erased -> Error (Cerror.Cerr_apply_erased (Cerror.diagnostic input.root "erased application"))
    | Anf.Local _ | Anf.Lit _ ->
        let* before, callee = atom head in let* binds, args = atoms args in
        let* after, result = unknown callee args in Ok (before @ binds @ after, result)
  and block = function
    | Anf.Return a -> let* binds, a = atom a in Ok { binds; tail = Return a }
    | Anf.Let (s, rhs, body) ->
        let* before, rhs = match rhs with
          | Anf.Atom a -> let* binds, a = atom a in Ok (binds, Atom a)
          | Anf.Apply (f, args) -> let* binds, result = application f args in Ok (binds, Atom result)
          | Anf.Lambda (param, lambda_body) ->
              let captures = Slots.elements (Slots.remove param (free lambda_body)) in
              let name = "$closure." ^ string_of_int !serial in incr serial;
              let* body = block lambda_body in
              generated := !generated @ [{ name; kind = Cterm.Closure; parameters = [param]; capture_slots = captures; body }];
              Ok ([], MkClo (name, List.map (fun s -> Cterm.ALocal s) captures)) in
        let* rest = block body in Ok { rest with binds = before @ [s, rhs] @ rest.binds }
    | Anf.Switch (scrut, branches) ->
        let* binds, scrut = atom scrut in
        let* branches = List.fold_left (fun acc (name, parameters, body) ->
          let* done_ = acc in
          let* projections = List.fold_left (fun acc (i, s) ->
            let* done_ = acc in let* field = Cterm.field ~arity:(List.length parameters) i |> Option.to_result
              ~none:(Cerror.Cerr_open_term (Cerror.diagnostic name "invalid constructor field")) in
            Ok (done_ @ [s, Proj (scrut, field)])) (Ok []) (List.mapi (fun i s -> i, s) parameters) in
          let* body = block body in
          Ok (done_ @ [Cterm.ctor name, { body with binds = projections @ body.binds }])) (Ok []) branches in
        Ok { binds; tail = Switch (scrut, branches) }
  in
  let* codes = List.fold_left (fun acc (d : Anf.definition) ->
    let* done_ = acc in
    counter := max_slot d;
    let* body = block d.body in
    Ok (done_ @ [{ name = d.name; kind = Cterm.Global; parameters = d.parameters; capture_slots = []; body }])) (Ok []) input.definitions in
  Ok { root = input.root; codes = codes @ !generated }
