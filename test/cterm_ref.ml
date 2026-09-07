(** Independent execution of the final IR and its differential harness.
    Dune copies this source into the driver build, sharing the machine
    without adding an interpreter dependency to the middle end. *)
open Tot_kernel
open Tot_interp
open Tally_cterm

let ( let* ) = Result.bind
type failure = Frontend of string | Middle of Cerror.t | Runtime of string
let message = function
  | Frontend text | Runtime text -> text
  | Middle error -> Cerror.render error
let kernel result = Result.map_error (fun error -> Runtime (Error.to_string error)) result
let middle result = Result.map_error (fun error -> Middle error) result
let surface result =
  Result.map_error (fun error -> Frontend (Tot_surface.Serror.to_string error)) result
let runtime text = Error (Runtime text)
type prepared = {
  state : Tot_surface.Run.state;
  declarations : Decl.t;
  terms : (string * Eterm.t) list;
}

(** Read each reachable stamped definition once without executing it. *)
let reachable globals =
  let rec term seen terms = function
    | Eterm.EVar _ | Eterm.EErased | Eterm.ELit _ -> Ok (seen, terms)
    | Eterm.ELam (_, body) -> term seen terms body
    | Eterm.EApp (fn, argument) | Eterm.ELet (_, fn, argument) ->
        let* seen, terms = term seen terms fn in
        term seen terms argument
    | Eterm.EMatch (scrutinee, branches) ->
        let* seen, terms = term seen terms scrutinee in
        List.fold_left
          (fun result (_, _, body) -> let* seen, terms = result in term seen terms body)
          (Ok (seen, terms)) branches
    | Eterm.EGlobal name -> global seen terms name
  and global seen terms name =
    if List.mem name seen then Ok (seen, terms)
    else
      let seen = name :: seen in
      let* entry = Global.find name globals
        |> Option.to_result ~none:(Middle (Cerror.Cerr_unknown_global
             (Cerror.diagnostic name "unknown runtime global"))) in
      match entry with
      | Global.Def definition ->
          let* erased = kernel (Erase.closed definition.def) in
          term seen ((name, erased) :: terms) erased
      | Global.Ctor _ | Global.Ind _ | Global.Prim _ | Global.Axiom _ -> Ok (seen, terms)
  in
  let* _, terms = global [] [] "main" in
  Ok (List.rev terms)

let elaborate ~policy ~st path =
  let* source = Tot_surface.Source.read path
    |> Result.map_error (fun error -> Frontend (path ^ ": " ^ Tot_surface.Source.message error)) in
  let* source, declarations = middle (Decl.source source) in
  let* tokens = surface (Tot_surface.Lexer.lex source) in
  let* items = surface (Tot_surface.Parser.parse tokens) in
  let* state = List.fold_left
    (fun result item -> let* state = result in
      surface (Tot_surface.Run.item ~exec:false ~policy state item))
    (Ok st) items in
  let* terms = reachable state.globals in
  Ok { state; declarations; terms }

let load ?(no_prelude = false) ?(no_axioms = false) path =
  let policy = { Tot_surface.Run.default_policy with no_axioms } in
  if no_prelude then elaborate ~policy ~st:Tot_surface.Run.initial path
  else
    let* source = Tot_surface.Bootstrap.prelude_source ()
      |> Result.map_error (fun (path, error) ->
           Frontend ("prelude: " ^ path ^ ": " ^ Tot_surface.Source.message error)) in
    let* st = surface (Tot_surface.Bootstrap.cached_state_of_src source) in
    elaborate ~policy ~st path

let pipeline ?arena_limit prepared =
  let* anf = middle (Anf.program prepared.state.globals ~root:"main") in
  let* clos = middle (Clos.program anf) in
  let* program = middle (Defun.program clos) in
  let* program = middle (Tramp.program program) in
  let* program = middle (Layout.program ?arena_limit program) in
  let* () = middle (Verify.program program) in
  Ok program

let constructors prepared =
  let rec names = function
    | Eterm.EVar _ -> [ "EVar" ]
    | Eterm.ELam (_, body) -> "ELam" :: names body
    | Eterm.EApp (fn, argument) -> "EApp" :: (names fn @ names argument)
    | Eterm.ELet (_, definition, body) -> "ELet" :: (names definition @ names body)
    | Eterm.EGlobal _ -> [ "EGlobal" ]
    | Eterm.EErased -> [ "EErased" ]
    | Eterm.ELit _ -> [ "ELit" ]
    | Eterm.EMatch (scrutinee, branches) ->
        "EMatch" :: (names scrutinee @ List.concat_map (fun (_, _, body) -> names body) branches)
  in
  List.concat_map (fun (_, body) -> names body) prepared.terms

(** The oracle reads checked source only, independently of every pass. *)
let interp prepared =
  let* globals = Global.StringMap.fold
    (fun name entry result ->
      let* globals = result in
      match entry with
      | Global.Def definition ->
          let* body = kernel (Erase.closed definition.def) in
          let guard = Tot_surface.Run.compute_guard ~name definition.def definition.rec_arg body in
          Ok (Interp.define globals ~name ~guard body)
      | Global.Ctor constructor ->
          let arity = List.length (List.filter
            (fun (quantity, _, _) -> Quantity.equal quantity Quantity.Many) constructor.args) in
          Ok (Interp.add_ctor globals ~name ~arity)
      | Global.Ind _ | Global.Axiom _ -> Ok (Interp.add_erased globals ~name)
      | Global.Prim primitive -> kernel (Interp.add_prim globals ~name ~prim:primitive.prim))
    prepared.state.globals (Ok Interp.empty_globals) in
  let* value = kernel (Interp.exec globals [] (Eterm.EGlobal "main")) in
  let* normalized = kernel (Interp.quote globals 0 value) in
  Ok (Pp.eterm [] normalized)

type value =
  | Literal of Literal.t
  | Constructor of string * value list
  | Closure of Cterm.code_tag * value list
  | Continuation of Cterm.kont_tag * value list
  | Erased
type locals = (Cterm.slot * value) list
let literal = function
  | Cterm.LStr text -> Literal.LString text
  | Cterm.LInt number -> Literal.LInt number
  | Cterm.LWord (width, sign, bits) -> Literal.LWord (Word.mk width sign bits)
let atom (locals : locals) = function
  | Cterm.ALocal slot -> List.assoc_opt slot locals
      |> Option.to_result ~none:(Runtime ("unbound slot " ^ string_of_int (Cterm.slot_index slot)))
  | Cterm.AGlobal constructor -> Ok (Constructor (Cterm.ctor_name constructor, []))
  | Cterm.ALit value -> Ok (Literal (literal value))
  | Cterm.AErased -> Ok Erased
let values locals atoms = List.fold_right
  (fun item result -> let* value = atom locals item in let* rest = result in Ok (value :: rest))
  atoms (Ok [])
let rec bind slots values =
  match slots, values with
  | [], [] -> Ok []
  | slot :: slots, value :: values -> let* rest = bind slots values in Ok ((slot, value) :: rest)
  | [], _ :: _ | _ :: _, [] -> runtime "reference call has the wrong arity"
let primitive prim values =
  let* literals = List.fold_right
    (fun value result ->
      let* rest = result in
      match value with
      | Literal value -> Ok (value :: rest)
      | Constructor _ | Closure _ | Continuation _ | Erased ->
          runtime "word primitive received a nonliteral") values (Ok []) in
  let* result = Word_delta.delta prim literals
    |> Option.to_result ~none:(Runtime ("unsupported reference primitive: " ^ Prim.name prim)) in
  match result with
  | Word_delta.RLit value -> Ok (Literal value)
  | Word_delta.RBool value -> Ok (Constructor ((if value then "true" else "false"), []))
  | Word_delta.ROrder order -> Ok (Constructor (Word.order_name order, []))

(** Known calls finish before their caller continues. Unknown calls carry
    the explicit continuation stack across tail transfers. *)
let rec code program pending tag captures arguments =
  let* body = Cterm.code_of_tag program tag
    |> Option.to_result ~none:(Runtime "reference code tag is out of range") in
  let* arguments = bind body.parameters arguments in
  let* captures = bind body.capture_slots captures in
  block program pending (arguments @ captures) body.body
and resume program pending tag captures result =
  let* continuation = Cterm.kont_of_tag program tag
    |> Option.to_result ~none:(Runtime "reference continuation tag is out of range") in
  let* captures = bind continuation.kont_capture_slots captures in
  block program pending ((continuation.kont_result, result) :: captures) continuation.kont_body
and returned program pending result =
  match pending with
  | [] -> Ok result
  | (tag, captures) :: rest -> resume program rest tag captures result
and apply program pending fn argument =
  match fn with
  | Closure (tag, captures) -> code program pending tag captures [ argument ]
  | Literal _ | Constructor _ | Continuation _ | Erased -> runtime "reference application of a nonclosure"
and block program pending locals body =
  let* locals, pending = List.fold_left
    (fun result (slot, expression) ->
      let* locals, pending = result in
      let* value, pending = rhs program pending locals expression in
      Ok ((slot, value) :: locals, pending)) (Ok (locals, pending)) body.Cterm.binds in
  match body.tail with
  | Cterm.TRet result -> let* result = atom locals result in returned program pending result
  | Cterm.TApply (fn, argument) ->
      let* fn = atom locals fn in let* argument = atom locals argument in
      apply program pending fn argument
  | Cterm.TResume (continuation, result) ->
      let* continuation = atom locals continuation in let* result = atom locals result in
      (match continuation with
      | Continuation (tag, captures) -> resume program pending tag captures result
      | Literal _ | Constructor _ | Closure _ | Erased -> runtime "reference resume of a noncontinuation")
  | Cterm.TSwitch (scrutinee, branches, default) ->
      let* scrutinee = atom locals scrutinee in
      (match scrutinee with
      | Constructor (name, _) ->
          let branch = List.find_opt
            (fun (constructor, _) -> String.equal (Cterm.ctor_name constructor) name) branches
            |> Option.fold ~none:default ~some:snd in
          block program pending locals branch
      | Literal _ | Closure _ | Continuation _ | Erased -> runtime "reference switch on a nonconstructor")
  | Cterm.TTrap Cterm.Trap_impossible_ctor -> runtime "Trap_impossible_ctor"
and rhs program pending locals = function
  | Cterm.RAtom item -> let* value = atom locals item in Ok (value, pending)
  | Cterm.RMkClo (tag, captures) ->
      let* captures = values locals captures in Ok (Closure (tag, captures), pending)
  | Cterm.RMkKont (tag, captures) ->
      let* captures = values locals captures in
      Ok (Continuation (tag, captures), (tag, captures) :: pending)
  | Cterm.RMkCon (constructor, arguments) ->
      let* arguments = values locals arguments in
      Ok (Constructor (Cterm.ctor_name constructor, arguments), pending)
  | Cterm.RProj (record, field) ->
      let* record = atom locals record in
      (match record with
      | Constructor (_, fields) ->
          let* value = List.nth_opt fields (Cterm.field_index field)
            |> Option.to_result ~none:(Runtime "reference projection is out of range") in
          Ok (value, pending)
      | Literal _ | Closure _ | Continuation _ | Erased -> runtime "reference projection from a nonconstructor")
  | Cterm.RPrim (prim, arguments) ->
      let* arguments = values locals arguments in let* value = primitive prim arguments in
      Ok (value, pending)
  | Cterm.RSyscall (Cterm.Syscall.Sol_log, _) -> runtime "reference syscall execution is unavailable at this stage"
  | Cterm.RCallKnown (tag, arguments) ->
      let* arguments = values locals arguments in let* value = code program [] tag [] arguments in
      Ok (value, pending)
  | Cterm.RApply (_, _) -> runtime "unlowered application reached the reference machine"

let rec quote = function
  | Literal value -> Ok (Eterm.ELit value)
  | Erased -> Ok Eterm.EErased
  | Constructor (name, arguments) -> List.fold_left
      (fun result argument -> let* fn = result in let* argument = quote argument in
        Ok (Eterm.EApp (fn, argument))) (Ok (Eterm.EGlobal name)) arguments
  | Closure _ | Continuation _ -> runtime "reference normalization expects a first-order result"
let run program =
  let* result = code program [] program.Cterm.entry [] [] in
  let* normalized = quote result in
  Ok (Pp.eterm [] normalized)

let fixtures =
  [ "cterm-id"; "cterm-capture"; "cterm-nested-capture"; "cterm-known-call";
    "cterm-selfrec"; "cterm-mutual"; "cterm-match-kept"; "cterm-word-tower";
    "cterm-div-zero"; "cterm-shift-wide" ]
let fixture_directory () =
  let executable =
    if Filename.is_relative Sys.executable_name then
      Filename.concat (Sys.getcwd ()) Sys.executable_name
    else Sys.executable_name
  in
  let rec search directory =
    let candidate = Filename.concat directory "test/fixtures" in
    if Sys.file_exists (Filename.concat candidate "cterm-id.tot") then Ok candidate
    else
      let parent = Filename.dirname directory in
      if String.equal parent directory then runtime "cannot locate reference fixtures"
      else search parent
  in
  search (Filename.dirname executable)
let write path lines =
  try
    Out_channel.with_open_text path (fun channel ->
      List.iter (fun line -> output_string channel (line ^ "\n")) lines);
    Ok ()
  with Sys_error text -> runtime text
let harness directory =
  let* () =
    try
      if not (Sys.file_exists directory) then Sys.mkdir directory 0o755;
      Ok ()
    with Sys_error text -> runtime text
  in
  let* fixture_directory = fixture_directory () in
  let* interp_lines, pipeline_lines, names = List.fold_left
    (fun result fixture ->
      let* interp_lines, pipeline_lines, names = result in
      let path = Filename.concat fixture_directory (fixture ^ ".tot") in
      let* prepared = load path in
      let* expected = interp prepared in
      let* program = pipeline prepared in
      let* actual = run program in
      Ok (expected :: interp_lines, actual :: pipeline_lines, constructors prepared @ names))
    (Ok ([], [], [])) fixtures in
  let* () = write (Filename.concat directory "interp.txt") (List.rev interp_lines) in
  let* () = write (Filename.concat directory "pipeline.txt") (List.rev pipeline_lines) in
  write (Filename.concat directory "constructors.txt") names
let () =
  match Array.to_list Sys.argv with
  | executable :: rest
    when List.mem (Filename.basename executable) [ "cterm_ref"; "cterm_ref.exe" ] ->
      let result = match rest with
        | [ directory ] -> harness directory
        | [] | _ :: _ :: _ -> runtime "usage: cterm_ref OUTPUT_DIRECTORY" in
      Result.fold ~ok:(fun () -> ())
        ~error:(fun error -> prerr_endline (message error); Stdlib.exit 2) result
  | [] | _ :: _ -> ()
