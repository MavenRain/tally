(** The tally CLI: [tally check FILE] elaborates and type-checks FILE
    through the VENDORED tot front end and executes nothing from it
    (M0-PLAN.md E1, plan 3295-3311).  It adds nothing to that front end
    except this binary's name and access to the word tower through it, so
    a `.tal` target is accepted by EXTENSION alone: the surface syntax IS
    tot's, and [Tot_surface.Source.read] classifies a path without ever
    reading its suffix.

    The build subcommand adds the middle end and reference execution.

    The check path mirrors `vendor/tot/bin/tot.ml` at vendor HEAD
    de61f4e (Stage E ruling (c) re-cite; plan 3300's `23,37,92-107` are
    the OLD pin's line numbers): [Source.read] at `bin/tot.ml:52`,
    [Run.script] at `:66`, the two prelude reads at `:152,158`, the usage
    string at `:240` and the flag parse at `:251`, 319 lines in all.

    Prelude resolution stays tot's exe-relative default
    ([Tot_surface.Bootstrap.prelude_path]), so an invocation of this
    binary out of `<tally>/_build/default/bin/` names its prelude through
    `TOT_PRELUDE`: the tally repo root is not a tot-shaped tree
    (plan 3387-3397). *)

(** The flags M0's checker accepts.  tot's `--require-main`,
    `--strict-json` and `--check-budget-ms` are NOT delivered at M0, so
    those policy fields keep [Tot_surface.Run.default_policy]'s values
    and the kernel budget stays unlimited. *)
type opts = { no_prelude : bool; no_axioms : bool; serror_exit : int }

(** The defaults are tot's: prelude auto-loaded, axioms permitted, and a
    script-level error exits the literal 1. *)
let default_opts : opts = { no_prelude = false; no_axioms = false; serror_exit = 1 }

(** The one usage line.  It is printed on STDERR: stdout carries only a
    rendered decision (tot's B4 channel rule). *)
let usage : string =
  "usage: tally check [--no-prelude] [--no-axioms] [--serror-exit N] FILE\n\
   \       tally build [--emit-none] [--verify] [--dump-cterm] [--run-cterm]\n\
   \                   [--run-interp] [--dump-eterm-ctors] [--arena-limit N]\n\
   \                   [--no-prelude] [--no-axioms] [-o IMAGE] [--ledger FILE] FILE\n\
   \       tally build [--ledger FILE] --print-syscall-keys"

(** Consume leading flags; the first non-flag argument ends the scan, and
    a leading "--" that is not a known flag is an error, so a typo can
    never be read as a file name.  Total: no raise, and the
    [String.length a >= 2] guard on the same line as [String.sub a 0 2]
    establishes that slice's precondition. *)
let rec parse_flags (opts : opts) (args : string list) : (opts * string list, string) result =
  match args with
  | "--no-prelude" :: rest -> parse_flags { opts with no_prelude = true } rest
  | "--no-axioms" :: rest -> parse_flags { opts with no_axioms = true } rest
  | "--serror-exit" :: n :: rest ->
      int_of_string_opt n
      |> Option.fold
           ~none:(Error ("--serror-exit expects an integer 0..255, got " ^ n))
           ~some:(fun (v : int) ->
             match () with
             | () when v < 0 || v > 255 -> Error ("--serror-exit out of range 0..255: " ^ n)
             | () -> parse_flags { opts with serror_exit = v } rest)
  | [ "--serror-exit" ] -> Error "--serror-exit expects an integer argument"
  | a :: _rest when String.length a >= 2 && String.equal (String.sub a 0 2) "--" (* @total-accessor *)
    ->
      Error ("unknown flag: " ^ a)
  | ([] | _ :: _) -> Ok (opts, args)

(** The check's [Tot_surface.Run.policy]: only `--no-axioms` is
    configurable at M0. *)
let policy_of_opts (o : opts) : Tot_surface.Run.policy =
  { Tot_surface.Run.no_axioms = o.no_axioms; require_main = false; strict_json = false }

(** Fold the target file against [st] with execution OFF, print the
    rendered lines on stdout, and report a failure on stderr.  An
    unusable target path is a DRIVER verdict and keeps the literal exit
    1, outside the [--serror-exit] mapping;  a
    [Tot_surface.Serror.driver_exit] error keeps its literal 2 the same
    way, so no fail-open install can demote either. *)
let check_file ~(serror_exit : int) ~(policy : Tot_surface.Run.policy)
    ~(st : Tot_surface.Run.state) (path : string) : int =
  Tot_surface.Source.read path
  |> Result.fold
       ~error:(fun (e : Tot_surface.Source.error) ->
         prerr_endline (path ^ ": " ^ Tot_surface.Source.message e);
         1)
       ~ok:(fun (src : string) ->
         Tot_surface.Run.script ~st ~policy ~exec:false src
         |> Result.fold
              ~ok:(fun ((lines, exit_code) : string list * int option) ->
                List.iter print_endline lines;
                Option.value exit_code ~default:0)
              ~error:(fun (e : Tot_surface.Serror.t) ->
                prerr_endline (path ^ ":" ^ Tot_surface.Serror.to_string e);
                match () with
                | () when Tot_surface.Serror.driver_exit e -> 2
                | () -> serror_exit))

(** The prelude-auto-loaded check: classify the prelude PATH first (an
    unusable one is a verdict about the INSTALLATION, so it takes the
    literal exit 1 outside the [--serror-exit] mapping), bootstrap once
    from the bytes that precheck already read, then fold the target
    against the bootstrapped state. *)
let check_with_prelude ~(serror_exit : int) ~(policy : Tot_surface.Run.policy) (path : string) :
    int =
  Tot_surface.Bootstrap.prelude_source ()
  |> Result.fold
       ~error:(fun ((ppath, e) : string * Tot_surface.Source.error) ->
         prerr_endline ("prelude: " ^ ppath ^ ": " ^ Tot_surface.Source.message e);
         1)
       ~ok:(fun (src : string) ->
         Tot_surface.Bootstrap.cached_state_of_src src
         |> Result.fold
              ~ok:(fun (st : Tot_surface.Run.state) -> check_file ~serror_exit ~policy ~st path)
              ~error:(fun (e : Tot_surface.Serror.t) ->
                prerr_endline ("prelude: " ^ Tot_surface.Serror.to_string e);
                serror_exit))

(** `check`'s flags, then exactly one positional path.  Any other shape
    (a stray-flag error, zero paths, or more than one) is the same exit-2
    usage report every malformed invocation gets. *)
let check (rest : string list) : int =
  parse_flags default_opts rest
  |> Result.fold
       ~error:(fun (msg : string) ->
         prerr_endline msg;
         2)
       ~ok:(fun ((opts, paths) : opts * string list) ->
         match paths with
         | [ path ] ->
             let policy = policy_of_opts opts in
             (match () with
             | () when opts.no_prelude ->
                 check_file ~serror_exit:opts.serror_exit ~policy ~st:Tot_surface.Run.initial path
             | () -> check_with_prelude ~serror_exit:opts.serror_exit ~policy path)
         | [] | _ :: _ :: _ ->
             prerr_endline usage;
             2)

type build_opts = {
  no_prelude : bool;
  no_axioms : bool;
  verify : bool;
  dump : bool;
  run_cterm : bool;
  run_interp : bool;
  dump_constructors : bool;
  arena_limit : int option;
  emit : bool;
  output : string option;
  ledger : string option;
  print_keys : bool;
}

let default_build = {
  no_prelude = false; no_axioms = false; verify = false; dump = false;
  run_cterm = false; run_interp = false; dump_constructors = false; arena_limit = None;
  emit = true; output = None; ledger = None; print_keys = false;
}

let rec build_flags options = function
  | "--emit-none" :: rest -> build_flags { options with emit = false } rest
  | "-o" :: path :: rest when not (String.starts_with ~prefix:"-" path) ->
      build_flags { options with output = Some path } rest
  | "--ledger" :: path :: rest when not (String.starts_with ~prefix:"-" path) ->
      build_flags { options with ledger = Some path } rest
  | "--print-syscall-keys" :: rest -> build_flags { options with print_keys = true } rest
  (* A following flag is never the path: consuming it would name an artifact
     after the option the user meant to pass. *)
  | "-o" :: _ | "--ledger" :: _ -> Error "output and ledger options require a path"
  | "--verify" :: rest -> build_flags { options with verify = true } rest
  | "--dump-cterm" :: rest -> build_flags { options with dump = true } rest
  | "--run-cterm" :: rest -> build_flags { options with run_cterm = true } rest
  | "--run-interp" :: rest -> build_flags { options with run_interp = true } rest
  | "--dump-eterm-ctors" :: rest -> build_flags { options with dump_constructors = true } rest
  | "--no-prelude" :: rest -> build_flags { options with no_prelude = true } rest
  | "--no-axioms" :: rest -> build_flags { options with no_axioms = true } rest
  | "--arena-limit" :: argument :: rest ->
      int_of_string_opt argument
      |> Option.fold ~none:(Error "--arena-limit expects a nonnegative integer")
           ~some:(fun value ->
             if value < 0 then Error "--arena-limit expects a nonnegative integer"
             else build_flags { options with arena_limit = Some value } rest)
  | [ "--arena-limit" ] -> Error "--arena-limit expects an integer argument"
  | argument :: _ when String.starts_with ~prefix:"--" argument ->
      Error ("unknown flag: " ^ argument)
  | [ path ] when not options.print_keys -> Ok (options, Some path)
  | [] when options.print_keys -> Ok (options, None)
  | [] | [ _ ] | _ :: _ :: _ -> Error usage

let ledger_path options =
  Option.value options.ledger ~default:(
    Filename.concat
      (Filename.dirname (Filename.dirname (Filename.dirname (Filename.dirname Sys.executable_name))))
      "dev/CITATION-LEDGER.md")

let target_params options =
  let open Cterm_reference in
  let open Tally_target in
  let* source = Tot_surface.Source.read (ledger_path options)
    |> Result.map_error (fun error -> Runtime (Tot_surface.Source.message error)) in
  let* ledger = Citation_ledger.parse source
    |> Result.map_error (fun _ -> Runtime "malformed citation ledger") in
  Target_params.of_ledger ledger "sbpf-v3"
  |> Result.map_error (function
       | Target_params.Row_unverified row -> Runtime ("Row_unverified " ^ row)
       | Target_params.Unknown_target target -> Runtime ("Unknown_target " ^ target))

(** Target primitive names are seeded only for emission. The host primitive
    carrier for solLog never reaches a host evaluator on this path. *)
let load_target options path =
  let open Cterm_reference in
  let open Tot_kernel in
  let policy = { Tot_surface.Run.default_policy with no_axioms = options.no_axioms } in
  let* state =
    if options.no_prelude then Ok Tot_surface.Run.initial
    else
      let* source = Tot_surface.Bootstrap.prelude_source ()
        |> Result.map_error (fun (path, error) ->
          Frontend ("prelude: " ^ path ^ ": " ^ Tot_surface.Source.message error)) in
      surface (Tot_surface.Bootstrap.cached_state_of_src source) in
  let signed = List.concat_map (fun (width, name) ->
    let signature = name ^ " -> " ^ name ^ " -> " ^ name in
    let div = Prim.Word_div (width, Word.Signed) in
    let rem = Prim.Word_mod (width, Word.Signed) in
    [Prim.name div, signature, div; Prim.name rem, signature, rem])
    [Word.W8, "I8"; Word.W16, "I16"; Word.W32, "I32"; Word.W64, "I64"] in
  let primitives = if options.no_prelude then [] else
    ("solLog", "String -> IO Unit", Prim.Print_line) :: signed in
  let* state = surface (Tot_surface.Bootstrap.seed_prims state primitives) in
  elaborate ~policy ~st:state path

let remove_temporary path =
  try Sys.remove path with Sys_error _ -> ()

let prepare_artifact path content =
  try
    let temporary = Filename.temp_file ~temp_dir:(Filename.dirname path) ".tally-" ".tmp" in
    (try
       Out_channel.with_open_bin temporary (fun channel -> Out_channel.output_string channel content);
       Ok temporary
     with Sys_error error ->
       remove_temporary temporary;
       Error (Cterm_reference.Runtime (path ^ ": " ^ error)))
  with Sys_error error -> Error (Cterm_reference.Runtime (path ^ ": " ^ error))

let write_artifacts output image manifest =
  let open Cterm_reference in
  let* image_temporary = prepare_artifact output image in
  let prepared = prepare_artifact (output ^ ".manifest") manifest in
  let result = Result.bind prepared (fun manifest_temporary ->
    let published =
      try
        Sys.rename image_temporary output;
        Sys.rename manifest_temporary (output ^ ".manifest");
        Ok ()
      with Sys_error error -> Error (Runtime (output ^ ": " ^ error)) in
    remove_temporary manifest_temporary;
    published) in
  remove_temporary image_temporary;
  result

type file_identity = Existing of int * int | New of string

let file_identity path =
  try
    let stat = Unix.stat path in
    match stat.Unix.st_kind with
    | Unix.S_REG -> Ok (Existing (stat.Unix.st_dev, stat.Unix.st_ino))
    | Unix.S_DIR | Unix.S_CHR | Unix.S_BLK | Unix.S_LNK | Unix.S_FIFO | Unix.S_SOCK ->
        Error (Cterm_reference.Runtime (path ^ ": expected a regular file"))
  with
  | Unix.Unix_error (Unix.ENOENT, _, _) ->
      (try Ok (New (Filename.concat (Unix.realpath (Filename.dirname path)) (Filename.basename path)))
       with Unix.Unix_error (error, _, _) ->
         Error (Cterm_reference.Runtime (path ^ ": " ^ Unix.error_message error)))
  | Unix.Unix_error (error, _, _) ->
      Error (Cterm_reference.Runtime (path ^ ": " ^ Unix.error_message error))

let check_destinations ~source ~ledger output =
  let open Cterm_reference in
  let* source = file_identity source in
  let* ledger = file_identity ledger in
  let* image = file_identity output in
  let* manifest = file_identity (output ^ ".manifest") in
  if image = source || image = ledger || manifest = source || manifest = ledger || image = manifest then
    Error (Runtime "image and manifest must be distinct from the source, ledger, and each other")
  else Ok ()

let emit_program options source program =
  let open Cterm_reference in
  let open Tally_emit in
  let emitted result = Result.map_error (fun error -> Runtime (Emit_error.to_string error)) result in
  let* params = target_params options in
  let* selected = emitted (Select.program params program) in
  let* labels = emitted (Link.labels selected.instructions) in
  let* instructions = emitted (Link.resolve selected.instructions) in
  let count = List.length instructions in
  let* starts = List.fold_left (fun result (name, label, frame_bytes) ->
    let* found = result in
    let* start = List.assoc_opt label labels
      |> Option.to_result ~none:(Runtime ("missing function label: " ^ label)) in
    Ok ((name, start, frame_bytes) :: found)) (Ok []) selected.functions in
  let starts = List.sort (fun (_, left, _) (_, right, _) -> compare left right) starts in
  let rec ranges = function
    | [] -> []
    | (name, start, frame_bytes) :: rest ->
        let stop = match rest with [] -> count | (_, next, _) :: _ -> next in
        Manifest.{ name; slot_start = start; slot_count = stop - start; frame_bytes } :: ranges rest in
  let functions = ranges starts in
  let symbols = List.map (fun (fn : Manifest.fn) -> fn.name, fn.slot_start, fn.slot_count) functions in
  let* entry = emitted (Entry.select ~name:"main" symbols) in
  let* code = emitted (Encode.encode params instructions) in
  let* image = emitted (Image.build params ~entry ~functions:symbols ~code ~rodata:selected.rodata) in
  let output = Option.value options.output ~default:(Filename.remove_extension (Filename.basename source) ^ ".so") in
  let* () = check_destinations ~source ~ledger:(ledger_path options) output in
    let manifest = Manifest.render ~functions ~instruction_count:count ~image_bytes:(Bytes.length image) in
    let* () = write_artifacts output (Bytes.to_string image) manifest in
    Printf.printf "build: wrote %s instructions=%d image-bytes=%d frame-reserve=%d\n"
      output count (Bytes.length image) Frame.reserve;
    Ok ()

let build arguments =
  let open Cterm_reference in
  build_flags default_build arguments
  |> Result.fold
       ~error:(fun text -> prerr_endline text; 2)
       ~ok:(fun (options, path) ->
         let result =
           if options.print_keys then
             let* params = target_params options in
             let table = Tally_target.Syscall_table.of_params params in
             List.fold_left (fun result name ->
               let* () = result in
               let* key = Tally_target.Syscall_table.key table name
                 |> Result.map_error (function Tally_target.Syscall_table.Unknown_syscall name -> Runtime ("Unknown_syscall " ^ name)) in
               Printf.printf "%s %lu\n" name key; Ok ()) (Ok ())
               (Tally_target.Syscall_table.names table)
           else
           let* path = path |> Option.to_result ~none:(Runtime "missing source path") in
           let* () = if options.emit && (options.run_interp || options.run_cterm) then
             Error (Runtime "reference execution requires --emit-none") else Ok () in
           let* prepared = if options.emit then load_target options path
             else load ~no_prelude:options.no_prelude ~no_axioms:options.no_axioms path in
           let* program = pipeline ?arena_limit:options.arena_limit prepared in
           (* Both reporting flags run the verifier themselves: a counter
              alone reports no verified fact. *)
           let* () =
             if options.verify then (
               let* () = middle (Tally_cterm.Verify.program program) in
               let counts = Tally_cterm.Verify.summary program in
               Printf.printf "verify: ok dense=%d konts=%d switch-defaults=%d callknown-edges=%d\n"
                 counts.dense counts.konts counts.switch_defaults counts.callknown_edges;
               Ok ())
             else Ok () in
           let* () =
             if options.dump then (
               let* () = middle (Tally_cterm.Verify.program program) in
               let counts = Tally_cterm.Verify.summary program in
               Printf.printf "VERIFY-OK dense=%d konts=%d switch-defaults=%d callknown-edges=%d\n"
                 counts.dense counts.konts counts.switch_defaults counts.callknown_edges;
               let slots = Array.to_seq program.codes
                 |> Seq.fold_left (fun largest (code : Tally_cterm.Cterm.code) ->
                      max largest code.frame_slots) 0 in
               Printf.printf "cterm: frame-slots=%d arena-words=%d strings=%d\n"
                 slots program.arena_words (List.length program.strings);
               Ok ())
             else Ok () in
           if options.dump_constructors then
             List.iter print_endline (List.sort_uniq String.compare (constructors prepared));
           let* () = if options.run_interp then interp prepared |> Result.map print_endline else Ok () in
           let* () = if options.run_cterm then run program |> Result.map print_endline else Ok () in
           if options.emit then emit_program options path program else Ok ()
         in
         Result.fold ~ok:(fun () -> 0)
           ~error:(fun error ->
             prerr_endline (message error);
             match error with Frontend _ -> 1 | Middle _ | Runtime _ -> 2)
           result)

let () =
  match Array.to_list Sys.argv with
  | _exe :: "check" :: rest -> Stdlib.exit (check rest)
  | _exe :: "build" :: rest -> Stdlib.exit (build rest)
  | [] | [ _ ] | _ :: _ :: _ ->
      prerr_endline usage;
      Stdlib.exit 2
