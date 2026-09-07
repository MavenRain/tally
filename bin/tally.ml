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
   \                   [--no-prelude] [--no-axioms] FILE"

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
}

let default_build = {
  no_prelude = false; no_axioms = false; verify = false; dump = false;
  run_cterm = false; run_interp = false; dump_constructors = false; arena_limit = None;
}

let rec build_flags options = function
  | "--emit-none" :: rest -> build_flags options rest
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
  | [ path ] -> Ok (options, path)
  | [] | _ :: _ :: _ -> Error usage

let build arguments =
  let open Cterm_reference in
  build_flags default_build arguments
  |> Result.fold
       ~error:(fun text -> prerr_endline text; 2)
       ~ok:(fun (options, path) ->
         let result =
           let* prepared = load ~no_prelude:options.no_prelude ~no_axioms:options.no_axioms path in
           let* program = pipeline ?arena_limit:options.arena_limit prepared in
           if options.verify then (
             let counts = Tally_cterm.Verify.summary program in
             Printf.printf "verify: ok dense=%d konts=%d switch-defaults=%d callknown-edges=%d\n"
               counts.dense counts.konts counts.switch_defaults counts.callknown_edges);
           if options.dump then (
             let counts = Tally_cterm.Verify.summary program in
             Printf.printf "VERIFY-OK dense=%d konts=%d switch-defaults=%d callknown-edges=%d\n"
               counts.dense counts.konts counts.switch_defaults counts.callknown_edges;
             let slots = Array.to_seq program.codes
               |> Seq.fold_left (fun largest (code : Tally_cterm.Cterm.code) ->
                    max largest code.frame_slots) 0 in
             Printf.printf "cterm: frame-slots=%d arena-words=%d strings=%d\n"
               slots program.arena_words (List.length program.strings));
           if options.dump_constructors then
             List.iter print_endline (List.sort_uniq String.compare (constructors prepared));
           let* () = if options.run_interp then interp prepared |> Result.map print_endline else Ok () in
           if options.run_cterm then run program |> Result.map print_endline else Ok ()
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
  | [ _exe; "--help" ] -> print_endline usage
  | [] | [ _ ] | _ :: _ :: _ ->
      prerr_endline usage;
      Stdlib.exit 2
