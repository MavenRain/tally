open Tot_kernel
let ( let* ) = Result.bind
type atom = Local of Cterm.slot | Global of string | Lit of Cterm.lit | Erased
type rhs = Atom of atom | Apply of atom * atom list | Lambda of Cterm.slot * block
and block = Return of atom | Let of Cterm.slot * rhs * block
  | Switch of atom * (string * Cterm.slot list * block) list
type definition = { name : string; parameters : Cterm.slot list; body : block }
type symbol = Defined of int | Constructor of int | Primitive of Prim.t | Erased_global
type t = { root : string; definitions : definition list; symbols : (string * symbol) list }

let prim_allowed name prim =
  let d = Cerror.diagnostic name (Prim.name prim) in
  match prim with
  | Prim.Read_stdin | Prim.Print_line | Prim.Exit_with | Prim.Get_env
  | Prim.Read_file | Prim.Write_file | Prim.Argv | Prim.Proc_run -> Error (Cerror.Cerr_host_io d)
  | Prim.String_concat | Prim.String_length | Prim.String_eq | Prim.String_contains
  | Prim.String_slice | Prim.String_split | Prim.String_to_int | Prim.Int_to_string -> Error (Cerror.Cerr_host_string d)
  | Prim.Json_parse | Prim.Json_serialize -> Error (Cerror.Cerr_host_json d)
  | Prim.Regex_test | Prim.Regex_match -> Error (Cerror.Cerr_host_regex d)
  | Prim.Int_add | Prim.Int_sub | Prim.Int_eq | Prim.Int_compare -> Error (Cerror.Cerr_boxed_int d)
  | Prim.Pure_div | Prim.Bind_div | Prim.Pure_io | Prim.Bind_io | Prim.Lift_io -> Error (Cerror.Cerr_effect_prim d)
  | Prim.Word_add _ | Prim.Word_sub _ | Prim.Word_mul _ | Prim.Word_and _
  | Prim.Word_or _ | Prim.Word_xor _ | Prim.Word_not _ | Prim.Word_shl _
  | Prim.Word_eq _ | Prim.Word_div _ | Prim.Word_mod _ | Prim.Word_shr _
  | Prim.Word_compare _ | Prim.Word_to_string _ -> Ok ()

let rec references = function
  | Eterm.EVar _ | Eterm.EErased | Eterm.ELit _ -> []
  | Eterm.EGlobal name -> [name]
  | Eterm.ELam (_, body) -> references body
  | Eterm.EApp (f, a) -> references f @ references a
  | Eterm.ELet (_, d, b) -> references d @ references b
  | Eterm.EMatch (s, branches) -> references s @ List.concat_map (fun (c, _, b) -> c :: references b) branches

let rec arity = function
  | Eterm.ELam (_, b) -> 1 + arity b
  | Eterm.EVar _ | Eterm.EApp _ | Eterm.ELet _ | Eterm.EGlobal _
  | Eterm.EErased | Eterm.EMatch _ | Eterm.ELit _ -> 0

let normalize name term =
  let counter = ref 0 in
  let fresh () =
    if !counter = max_int then Error (Cerror.Cerr_arena_over (Cerror.diagnostic name "local index overflow")) else
    let* s = Cterm.slot !counter |> Option.to_result ~none:(Cerror.Cerr_open_term (Cerror.diagnostic name "negative local")) in
    incr counter; Ok s
  in
  let rec norm env term k =
    let bind r = let* s = fresh () in let* b = k (Local s) in Ok (Let (s, r, b)) in
    match term with
    | Eterm.EVar i ->
        let* s = (if i < 0 then None else List.nth_opt env i) |> Option.to_result
          ~none:(Cerror.Cerr_open_term (Cerror.diagnostic name "free erased variable")) in k (Local s)
    | Eterm.EGlobal n -> k (Global n)
    | Eterm.EErased -> k Erased
    | Eterm.ELit (Literal.LString s) -> k (Lit (Cterm.LStr s))
    | Eterm.ELit (Literal.LInt _) -> Error (Cerror.Cerr_boxed_int (Cerror.diagnostic name "boxed integer literal"))
    | Eterm.ELit (Literal.LWord w) -> k (Lit (Cterm.LWord (w.width, w.sign, w.bits)))
    | Eterm.ELam (_, body) ->
        let* param = fresh () in
        let* body = norm (param :: env) body (fun a -> Ok (Return a)) in bind (Lambda (param, body))
    | Eterm.ELet (_, value, body) -> norm env value (fun a ->
        let* s = fresh () in let* b = norm (s :: env) body k in Ok (Let (s, Atom a, b)))
    | Eterm.EApp _ ->
        let rec spine term args = match term with
          | Eterm.EApp (f, a) -> spine f (a :: args)
          | Eterm.EVar _ | Eterm.ELam _ | Eterm.ELet _ | Eterm.EGlobal _
          | Eterm.EErased | Eterm.EMatch _ | Eterm.ELit _ -> term, args
        in
        let head, args = spine term [] in
        norm env head (fun h ->
          let rec arguments done_ = function
            | [] -> bind (Apply (h, List.rev done_))
            | a :: rest -> norm env a (fun a -> arguments (a :: done_) rest)
          in arguments [] args)
    | Eterm.EMatch (scrut, branches) -> norm env scrut (fun a ->
        let* branches = List.fold_left (fun acc (c, names, body) ->
          let* done_ = acc in
          let* slots = List.fold_left (fun acc _ -> let* slots = acc in let* s = fresh () in Ok (s :: slots)) (Ok []) names in
          let* body = norm (slots @ env) body k in Ok ((c, List.rev slots, body) :: done_)) (Ok []) branches in
        Ok (Switch (a, List.rev branches)))
  in
  let rec parameters env params = function
    | Eterm.ELam (_, b) -> let* s = fresh () in parameters (s :: env) (s :: params) b
    | (Eterm.EVar _ | Eterm.EApp _ | Eterm.ELet _ | Eterm.EGlobal _
      | Eterm.EErased | Eterm.EMatch _ | Eterm.ELit _) as b ->
        let* body = norm env b (fun a -> Ok (Return a)) in Ok { name; parameters = List.rev params; body }
  in parameters [] [] term

let program globals ~root =
  let rec collect seen definitions symbols = function
    | [] -> Ok { root; definitions; symbols }
    | name :: rest ->
        if List.mem name seen then collect seen definitions symbols rest else
        let seen = name :: seen in
        let* entry = Global.find name globals |> Option.to_result
          ~none:(Cerror.Cerr_unknown_global (Cerror.diagnostic name "missing global")) in
        match entry with
        | Global.Def d ->
            let* term = Erase.closed d.def |> Result.map_error (fun _ -> Cerror.Cerr_open_term (Cerror.diagnostic name "erasure rejected definition")) in
            let* definition = normalize name term in
            collect seen (definitions @ [definition]) (symbols @ [name, Defined (arity term)]) (rest @ references term)
        | Global.Ctor c ->
            if String.equal c.ind "Nat" then Error (Cerror.Cerr_unary_numeral (Cerror.diagnostic name "unary runtime numeral")) else
            let kept = List.fold_left (fun n (q, _, _) -> match q with Quantity.Zero -> n | Quantity.Many -> n + 1) 0 c.args in
            collect seen definitions (symbols @ [name, Constructor kept]) rest
        | Global.Prim p -> let* () = prim_allowed name p.prim in
            collect seen definitions (symbols @ [name, Primitive p.prim]) rest
        | Global.Ind _ -> collect seen definitions (symbols @ [name, Erased_global]) rest
        | Global.Axiom _ -> Error (Cerror.Cerr_open_term (Cerror.diagnostic name "runtime axiom"))
  in collect [] [] [] [root]
