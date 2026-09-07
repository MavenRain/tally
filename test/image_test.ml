open Tally_emit
open Tally_target
let ( let* ) = Result.bind

let failures = ref []
let check name passed =
  Printf.printf "%s %s\n" (if passed then "PASS" else "FAIL") name;
  if not passed then failures := name :: !failures

let rejects name result = check name (Result.is_error result)

let run ledger =
  let* rows = Citation_ledger.parse ledger |> Result.map_error (fun _ -> "ledger parse") in
  let* params = Target_params.of_ledger rows "sbpf-v3" |> Result.map_error (fun _ -> "target parameters") in
  let instruction opcode = Encode.{ opcode; dst = 0; src = 0; off = 0; imm = 0l } in
  let mov = instruction (Target_params.op_mov64_imm params) in
  let ret = instruction (Target_params.op_return params) in
  let* code = Encode.encode params [mov; ret] |> Result.map_error Emit_error.to_string in
  check "S17 exact sixteen-byte floor"
    (Bytes.to_string code = "\183\000\000\000\000\000\000\000\157\000\000\000\000\000\000\000");
  rejects "opcode range" (Encode.encode params [{ mov with opcode = 256 }]);
  rejects "register nibble range" (Encode.encode params [{ mov with src = 16 }]);
  rejects "branch field range" (Encode.encode params [{ mov with off = 1 lsl 15 }]);
  rejects "duplicate labels" (Link.resolve [Label "x"; Insn mov; Label "x"; Insn ret]);
  rejects "missing label" (Link.resolve [Branch (mov, "missing"); Insn ret]);
  rejects "label at code end" (Link.resolve [Branch (mov, "end"); Label "end"]);
  let* branches = Link.resolve [Label "start"; Branch (mov, "finish"); Insn mov; Label "finish"; Branch (ret, "start")]
    |> Result.map_error Emit_error.to_string in
  check "relative branches use instruction slots"
    (List.map (fun (instruction : Encode.insn) -> instruction.off) branches = [1; 0; -3]);
  let* calls = Link.resolve [Call (mov, "fn"); Insn ret; Label "fn"; Insn ret]
    |> Result.map_error Emit_error.to_string in
  check "relative call uses following instruction"
    (List.map (fun (instruction : Encode.insn) -> instruction.imm) calls = [1l; 0l; 0l]);
  let functions = ["main", 0, 2] in
  let* image = Image.build params ~entry:0 ~functions ~code ~rodata:""
    |> Result.map_error Emit_error.to_string in
  Printf.printf "IMAGE floor %s\n" (String.concat "" (List.of_seq (Bytes.to_seq image) |> List.map (fun c -> Printf.sprintf "%02x" (Char.code c))));
  rejects "empty image" (Image.build params ~entry:0 ~functions:[] ~code:Bytes.empty ~rodata:"");
  rejects "missing function coverage" (Image.build params ~entry:0 ~functions:["main", 0, 1] ~code ~rodata:"");
  rejects "function gap" (Image.build params ~entry:1 ~functions:["main", 1, 1] ~code ~rodata:"");
  rejects "entry inside function" (Image.build params ~entry:1 ~functions ~code ~rodata:"");
  rejects "duplicate function name" (Image.build params ~entry:0 ~functions:["main", 0, 1; "main", 1, 1] ~code ~rodata:"");
  rejects "invalid symbol name" (Image.build params ~entry:0 ~functions:["ma\000in", 0, 2] ~code ~rodata:"");
  rejects "oversized static image" (Image.build params ~entry:0 ~functions ~code ~rodata:(String.make (Target_params.image_cap_bytes params) 'x'));
  Ok ()

let read path =
  try Ok (In_channel.with_open_bin path In_channel.input_all)
  with Sys_error error -> Error error

let () =
  let result = match Array.to_list Sys.argv with
    | [_; ledger] -> let* text = read ledger in run text
    | [] | [_] | _ :: _ :: _ -> Error "usage: image_test LEDGER" in
  Result.iter_error (fun error -> prerr_endline error; failures := error :: !failures) result;
  Stdlib.exit (if !failures = [] then 0 else 1)
