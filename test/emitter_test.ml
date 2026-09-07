open Tot_kernel
open Tally_cterm
open Tally_emit
module Params = Tally_target.Target_params
let ( let* ) = Result.bind
let failure text = Error text
let emit_error result = Result.map_error Emit_error.to_string result
let cterm_error result = Result.map_error Cerror.render result
let slot index = Cterm.slot index |> Option.to_result ~none:"test requested a negative slot"
let word width sign bits = Cterm.ALit (Cterm.LWord (width, sign, bits))
let make_program body =
  let entry, codes = Cterm.append_code [] ~name:"main" ~kind:Cterm.Global ~parameters:[] ~capture_slots:[] ~body in
  let program = Cterm.{ codes = Array.of_list codes; konts = [||]; entry; arena_words = 0; rodata = ""; strings = [] } in
  let* program = cterm_error (Layout.program program) in
  let* () = cterm_error (Verify.program program) in
  Ok program
let primitive_program primitive arguments =
  let* result = slot 0 in
  make_program Cterm.{ binds = [result, RPrim (primitive, arguments)]; tail = TRet (ALocal result) }
let comparison_program primitive arguments constructors =
  let* result = slot 0 in
  let arms = List.mapi (fun index name -> Cterm.ctor name,
    Cterm.{ binds = []; tail = TRet (word Word.W64 Word.Unsigned (Int64.of_int (index + 7))) }) constructors in
  make_program Cterm.{ binds = [result, RPrim (primitive, arguments)];
    tail = TSwitch (ALocal result, arms, { binds = []; tail = TTrap Trap_impossible_ctor }) }
let image params program =
  let* selected = emit_error (Select.program params program) in
  let* labels = emit_error (Link.labels selected.instructions) in
  let* insns = emit_error (Link.resolve selected.instructions) in
  let* code = emit_error (Encode.encode params insns) in
  let* functions = List.fold_left (fun result (name, label, _) ->
    let* functions = result in
    let* start = List.assoc_opt label labels |> Option.to_result ~none:"selected function label is absent" in
    Ok ((name, start, List.length insns - start) :: functions)) (Ok []) selected.functions in
  emit_error (Image.build params ~entry:0 ~functions ~code ~rodata:selected.rodata)
let hex bytes = Bytes.to_seq bytes |> Seq.map (fun byte -> Printf.sprintf "%02x" (Char.code byte)) |> List.of_seq |> String.concat ""
let output params name expected program =
  let* bytes = image params program in
  Printf.printf "CASE %s %Lu %s\n" name expected (hex bytes);
  Ok ()
let cases width =
  let unsigned n = word width Word.Unsigned n in
  let signed n = word width Word.Signed n in
  let mask n = (Word.mk width Word.Unsigned n).bits in
  let amount n = word Word.W32 Word.Unsigned n in
  let bits = match width with Word.W8 -> 8 | Word.W16 -> 16 | Word.W32 -> 32 | Word.W64 -> 64 in
  [ "add-wrap", Prim.Word_add (width, Word.Unsigned), [unsigned (-1L); unsigned 1L], 0L;
    "subtract-wrap", Prim.Word_sub (width, Word.Unsigned), [unsigned 0L; unsigned 1L], mask (-1L);
    "multiply", Prim.Word_mul (width, Word.Unsigned), [unsigned 17L; unsigned 15L], 255L;
    "and", Prim.Word_and (width, Word.Unsigned), [unsigned 170L; unsigned 204L], 136L;
    "or", Prim.Word_or (width, Word.Unsigned), [unsigned 170L; unsigned 85L], 255L;
    "xor", Prim.Word_xor (width, Word.Unsigned), [unsigned 170L; unsigned 204L], 102L;
    "not", Prim.Word_not (width, Word.Unsigned), [unsigned 0L], mask (-1L);
    "udiv", Prim.Word_div (width, Word.Unsigned), [unsigned 255L; unsigned 3L], 85L;
    "urem", Prim.Word_mod (width, Word.Unsigned), [unsigned 255L; unsigned 7L], 3L;
    "udiv-zero", Prim.Word_div (width, Word.Unsigned), [unsigned 7L; unsigned 0L], 0L;
    "urem-zero", Prim.Word_mod (width, Word.Unsigned), [unsigned 7L; unsigned 0L], 7L;
    "sdiv-negative", Prim.Word_div (width, Word.Signed), [signed (-7L); signed 3L], mask (-2L);
    "srem-negative", Prim.Word_mod (width, Word.Signed), [signed (-7L); signed 3L], mask (-1L);
    "sdiv-zero", Prim.Word_div (width, Word.Signed), [signed (-7L); signed 0L], 0L;
    "srem-zero", Prim.Word_mod (width, Word.Signed), [signed (-7L); signed 0L], mask (-7L);
    "shl", Prim.Word_shl (width, Word.Unsigned), [unsigned 3L; amount 2L], 12L;
    "shr", Prim.Word_shr (width, Word.Unsigned), [unsigned 128L; amount 2L], 32L;
    "signed-shr", Prim.Word_shr (width, Word.Signed), [signed (-8L); amount 2L], mask (-2L);
    "shl-width", Prim.Word_shl (width, Word.Unsigned), [unsigned 1L; amount (Int64.of_int bits)], 0L;
    "shr-wide", Prim.Word_shr (width, Word.Signed), [signed (-1L); amount 4294967295L], 0L ]
let comparison_cases width =
  [ "equal", Prim.Word_eq (width, Word.Unsigned), [word width Word.Unsigned 7L; word width Word.Unsigned 7L], ["false"; "true"], 8L;
    "unequal", Prim.Word_eq (width, Word.Unsigned), [word width Word.Unsigned 7L; word width Word.Unsigned 8L], ["false"; "true"], 7L;
    "unsigned-compare", Prim.Word_compare (width, Word.Unsigned), [word width Word.Unsigned (-1L); word width Word.Unsigned 1L], ["lt"; "eq"; "gt"], 9L;
    "signed-compare", Prim.Word_compare (width, Word.Signed), [word width Word.Signed (-1L); word width Word.Signed 1L], ["lt"; "eq"; "gt"], 7L ]
let spill_program count =
  let* values = List.fold_left (fun result index ->
    let* values = result in let* local = slot index in
    Ok (values @ [local, Cterm.RAtom (word Word.W64 Word.Unsigned (Int64.of_int (index + 1)))]))
    (Ok []) (List.init count Fun.id) in
  let* initial = slot 0 in
  let* binds, result = List.fold_left (fun outcome (index, (value, _)) ->
    let* binds, previous = outcome in let* destination = slot (count + index) in
    Ok (binds @ [destination, Cterm.RPrim (Prim.Word_add (Word.W64, Word.Unsigned), [Cterm.ALocal previous; Cterm.ALocal value])], destination))
    (Ok (values, initial)) (List.mapi (fun index value -> index, value) (List.filteri (fun index _ -> index > 0) values)) in
  make_program Cterm.{ binds; tail = TRet (ALocal result) }
let kind = function
  | Emit_error.Register_convention_undischarged -> "convention"
  | Emit_error.Frame_overflow _ -> "frame"
  | Emit_error.Call_graph_cycle _ -> "cycle"
  | Emit_error.Arena_overflow _ -> "arena"
  | Emit_error.Unsupported_prim _ | Emit_error.Unsupported_signed_op | Emit_error.Image_too_large _
  | Emit_error.Unknown_syscall _ | Emit_error.Input_truncated _ | Emit_error.Depth_budget_exceeded _
  | Emit_error.Depth_undeclared _ | Emit_error.Invalid_encoding _ | Emit_error.Invalid_image _
  | Emit_error.Unsupported_term _ -> "unexpected"
let expect_error name expected result =
  Result.fold ~ok:(fun _ -> failure (name ^ " unexpectedly succeeded"))
    ~error:(fun error -> if String.equal (kind error) expected then Ok () else failure (name ^ ": " ^ Emit_error.to_string error)) result
let structure params =
  let* local = slot 0 in
  let body = Cterm.{ binds = []; tail = TRet (word Word.W64 Word.Unsigned 0L) } in
  let tag, codes = Cterm.append_code [] ~name:"recursive" ~kind:Cterm.Global ~parameters:[] ~capture_slots:[] ~body in
  let codes = List.map (fun (code : Cterm.code) -> { code with body = { binds = [local, RCallKnown (tag, [])]; tail = TRet (ALocal local) } }) codes in
  let recursive = Cterm.{ codes = Array.of_list codes; konts = [||]; entry = tag; arena_words = 0; rodata = ""; strings = [] } in
  let* () = expect_error "native cycle" "cycle" (Callgraph.program recursive) in
  let parameter_tag, parameter_codes = Cterm.append_code [] ~name:"parameter" ~kind:Cterm.Global
    ~parameters:[local] ~capture_slots:[] ~body:Cterm.{ binds = []; tail = TRet (ALocal local) } in
  let parameter = Cterm.{ recursive with codes = Array.of_list parameter_codes; entry = parameter_tag } in
  let* parameter = cterm_error (Layout.program parameter) in
  let* () = expect_error "argument convention" "convention" (Select.program params parameter) in
  let* big = spill_program (Params.frame_bytes params) in
  let* big_graph = emit_error (Callgraph.program big) in
  let* () = expect_error "spill frame" "frame" (Frame.program params big big_graph) in
  let* small = make_program body in
  let too_large = { small with arena_words = Params.heap_bytes params } in
  let* small_graph = emit_error (Callgraph.program small) in
  let* () = expect_error "arena" "arena" (Frame.program params too_large small_graph) in
  let chain_length = Params.max_native_call_depth params + 1 in
  let _, chain = List.fold_left (fun (_, codes) index ->
    Cterm.append_code codes ~name:("depth" ^ string_of_int index) ~kind:Cterm.Global ~parameters:[] ~capture_slots:[] ~body)
    (tag, []) (List.init chain_length Fun.id) in
  let chain = List.mapi (fun index (code : Cterm.code) ->
    List.nth_opt chain (index + 1) |> Option.fold ~none:code ~some:(fun (next : Cterm.code) ->
      { code with body = { binds = [local, RCallKnown (next.code_id, [])]; tail = TRet (ALocal local) } })) chain in
  let* first = List.nth_opt chain 0 |> Option.to_result ~none:"depth chain is empty" in
  let native = Cterm.{ small with codes = Array.of_list chain; entry = first.code_id } in
  let* native = cterm_error (Layout.program native) in
  let* native_graph = emit_error (Callgraph.program native) in
  let* () = expect_error "native depth" "frame" (Frame.program params native native_graph) in
  print_endline "STRUCTURE ok";
  Ok ()
let run path =
  let* text = Tot_surface.Source.read path |> Result.map_error Tot_surface.Source.message in
  let* ledger = Tally_target.Citation_ledger.parse text |> Result.map_error Tally_target.Citation_ledger.pp_error in
  let* params = Params.of_ledger ledger "sbpf-v3" |> Result.map_error (function
    | Params.Row_unverified row -> "unverified ledger row " ^ row
    | Params.Unknown_target target -> "unknown target " ^ target) in
  let* () = structure params in
  let* () = List.fold_left (fun outcome width ->
    let* () = outcome in
    let family = match width with Word.W8 -> "8" | Word.W16 -> "16" | Word.W32 -> "32" | Word.W64 -> "64" in
    let* () = List.fold_left (fun outcome (name, primitive, arguments, expected) ->
      let* () = outcome in let* program = primitive_program primitive arguments in
      output params (name ^ "-" ^ family) expected program) (Ok ()) (cases width) in
    List.fold_left (fun outcome (name, primitive, arguments, constructors, expected) ->
      let* () = outcome in let* program = comparison_program primitive arguments constructors in
      output params (name ^ "-" ^ family) expected program) (Ok ()) (comparison_cases width))
    (Ok ()) [Word.W8; Word.W16; Word.W32; Word.W64] in
  let* () = List.fold_left (fun outcome bits ->
    let* () = outcome in let* program = make_program Cterm.{ binds = []; tail = TRet (word Word.W64 Word.Unsigned bits) } in
    output params (Printf.sprintf "literal-%Lx" bits) bits program)
    (Ok ()) [4294967295L; 4294967296L; 9223372036854775807L; Int64.min_int; -1L] in
  let* spill = spill_program 12 in
  output params "spill-live-values" 78L spill
let () =
  let result = match Array.to_list Sys.argv with
    | [_; path] -> run path
    | [] | [_] | _ :: _ :: _ :: _ -> failure "usage: emitter_test LEDGER" in
  Result.fold ~ok:(fun () -> ()) ~error:(fun text -> prerr_endline text; Stdlib.exit 1) result
