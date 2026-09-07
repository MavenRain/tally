open Tally_target

let failures = ref []
let check label condition = if not condition then failures := label :: !failures
let header = "| id | fact | value | obligation | status |\n|---|---|---|---|---|\n"
let row id status = "| " ^ id ^ " | fact | value | pin | " ^ status ^ " |"
let fixture rows = header ^ String.concat "\n" (List.map (fun (id, status) -> row id status) rows)

let mutate id replacement text =
  text |> String.split_on_char '\n'
  |> List.filter_map (fun line ->
       if String.starts_with ~prefix:("| " ^ id ^ " |") line then replacement line else Some line)
  |> String.concat "\n"

let expect_error label predicate text =
  Citation_ledger.parse text
  |> Result.fold ~ok:(fun _ -> check label false) ~error:(fun error -> check label (predicate error))

let malformed = function
  | Citation_ledger.Malformed_table _ -> true
  | Citation_ledger.No_table | Citation_ledger.Duplicate_row _ | Citation_ledger.Invalid_status _ -> false

let bad_status = function
  | Citation_ledger.Invalid_status _ -> true
  | Citation_ledger.No_table | Citation_ledger.Duplicate_row _ | Citation_ledger.Malformed_table _ -> false

let parser_tests actual =
  check "no table" (Citation_ledger.parse "prose" = Error Citation_ledger.No_table);
  expect_error "missing separator" malformed "| id | fact | value | obligation | status |";
  expect_error "bad separator" malformed
    "| id | fact | value | obligation | status |\n|---|---|--|---|---|\n";
  expect_error "half row" malformed
    (mutate "C7" (fun line -> Some (String.of_seq (Seq.take (String.length line / 2) (String.to_seq line)))) actual);
  expect_error "missing terminal pipe" malformed (header ^ "| C7 | fact | value | pin | VERIFIED pin");
  expect_error "extra cell" malformed (header ^ "| C7 | fact | value | pin | VERIFIED pin | extra |");
  expect_error "row outside table" malformed (row "C7" "VERIFIED pin");
  expect_error "duplicate row"
    (function
      | Citation_ledger.Duplicate_row { id; _ } -> String.equal id "C7"
      | Citation_ledger.No_table | Citation_ledger.Malformed_table _ | Citation_ledger.Invalid_status _ -> false)
    (fixture [ "C7", "VERIFIED pin"; "C7", "UNVERIFIED" ]);
  List.iter (fun status -> expect_error ("status " ^ status) bad_status (fixture [ "C7", status ]))
    [ ""; "VERIFIED"; "VERIFIED-ish pin"; "not VERIFIED pin" ];
  Citation_ledger.parse (fixture [ "C7", "VERIFIED pin"; "S18", "UNVERIFIED"; "C11", "VERIFIED-REFUTED pin" ])
  |> Result.fold ~error:(fun _ -> check "status fixture parses" false)
       ~ok:(fun ledger ->
         check "verified positive" (Citation_ledger.verified ledger "C7");
         List.iter (fun id -> check ("unavailable " ^ id) (not (Citation_ledger.verified ledger id)))
           [ "ABSENT"; "S18"; "C11" ];
         check "source order" (Citation_ledger.rows ledger = [ "C7"; "S18"; "C11" ]));
  Citation_ledger.parse (header ^ "| C7 | escaped \\| pipe | value | pin | VERIFIED pin |\n")
  |> Result.fold ~error:(fun _ -> check "escaped delimiter" false)
       ~ok:(fun ledger -> check "escaped delimiter" (Citation_ledger.verified ledger "C7"));
  let complete = row "C7" "VERIFIED pin" in
  List.init (String.length complete - 1) (fun n -> n + 1)
  |> List.iter (fun length ->
       let prefix = String.of_seq (Seq.take length (String.to_seq complete)) in
       check "truncated row" (Result.is_error (Citation_ledger.parse (header ^ prefix))))

let expect_missing id text =
  Citation_ledger.parse text
  |> Result.fold ~error:(fun error -> check (Citation_ledger.pp_error error) false)
       ~ok:(fun ledger ->
         check ("unavailable target row " ^ id)
           (Target_params.of_ledger ledger "sbpf-v3" = Error (Target_params.Row_unverified id)))

let check_params params =
  check "S18 unavailable"
    (Target_params.require_calling_convention params = Error (Target_params.Row_unverified "S18"));
  check "whole stack and per-frame limit"
    (Target_params.stack_bytes params = Target_params.frame_bytes params * Target_params.max_native_call_depth params
     && Target_params.stack_bytes params > Target_params.frame_bytes params);
  check "image and packet caps differ" (Target_params.image_cap_bytes params > Target_params.tx_byte_cap params);
  check "V3 memory opcode" (Target_params.opcode params "LD_8B_REG" = Some 0x9c);
  check "V3 product opcode" (Target_params.opcode params "LMUL64_REG" = Some 0x9e);
  check "deprecated product excluded" (Target_params.opcode params "MUL64_REG" = None);
  check "unknown opcode" (Target_params.opcode params "not-an-opcode" = None);
  let regions = Region_map.of_params params in
  check "region origin" (Region_map.bytecode regions = 0L);
  [ Region_map.bytecode regions, Region_map.rodata regions;
    Region_map.rodata regions, Region_map.stack regions;
    Region_map.stack regions, Region_map.heap regions;
    Region_map.heap regions, Region_map.input regions ]
  |> List.iter (fun (a, b) -> check "region spacing" (Int64.sub b a = Target_params.region_size params));
  let table = Syscall_table.of_params params in
  check "three syscalls" (List.length (Syscall_table.names table) = 3);
  check "unknown syscall" (Syscall_table.key table "sol_log" = Error (Syscall_table.Unknown_syscall "sol_log"));
  List.iter (fun name -> check ("bound syscall " ^ name) (Result.is_ok (Syscall_table.key table name)))
    (Syscall_table.names table)

let params_tests actual ledger =
  check "real ledger row count" (List.length (Citation_ledger.rows ledger) = 36);
  check "unknown target" (Target_params.of_ledger ledger "unknown" = Error (Target_params.Unknown_target "unknown"));
  List.iter (fun id ->
    expect_missing id (mutate id (fun _ -> None) actual);
    List.iter (fun status -> expect_missing id (mutate id (fun _ -> Some (row id status)) actual))
      [ "UNVERIFIED"; "VERIFIED-REFUTED pin" ]) Target_params.required_rows;
  (* The convention capability is a function of the ledger's own S18 cell and
     of nothing else, which is the OQ-3 discharge shape: a positively VERIFIED
     cell opens it, and every other status token leaves it closed.
     Citation_ledger owns which tokens count as positive. *)
  let convention status expected label =
    Citation_ledger.parse (mutate "S18" (fun _ -> Some (row "S18" status)) actual)
    |> Result.fold ~error:(fun _ -> check (label ^ ": fixture") false)
         ~ok:(fun ledger ->
           Target_params.of_ledger ledger "sbpf-v3"
           |> Result.fold ~error:(fun _ -> check (label ^ ": leaf params") false)
                ~ok:(fun params -> check label (Target_params.require_calling_convention params = expected))) in
  convention "VERIFIED arbitrary token" (Ok ()) "a VERIFIED S18 cell is the only discharge";
  List.iter (fun status ->
    convention status (Error (Target_params.Row_unverified "S18"))
      ("status cannot invent convention: " ^ status))
    [ "UNVERIFIED"; "VERIFIED-REFUTED pin" ];
  Target_params.of_ledger ledger "sbpf-v3"
  |> Result.fold ~error:(fun _ -> check "real ledger constructs leaf target" false) ~ok:check_params

let murmur_tests () =
  (* Independent vectors from murmur3 commit
     2c39087f094ae982a463e1cda9cf4d483a09192b, tests/test.rs.
     Cover every tail length, repeated blocks, and high UTF-8 bytes. *)
  [ "", 0l;
    "1", 0x9416ac93l; "12", 0xf9d2ef15l; "123", 0x9eb471ebl;
    "1234", 0x721c5dc3l; "12345", 0x13a51193l; "123456", 0xbf60eab8l;
    "1234567", 0xb7ef82f7l; "12345678", 0x91b313cel; "123456789", 0xb4fef382l;
    "1234567890", 0x3204634dl; "12345678901", 0x3ca173d0l;
    "123456789012", 0x6c75e419l; "1234567890123", 0xcaf7e549l;
    "12345678901234", 0x57ae5bd1l; "123456789012345", 0x09bb660cl;
    "1234567890123456", 0x06b2ff24l; "12345678901234567", 0xc50a5d2bl;
    "123456789012345678", 0xe970a44fl; "1234567890123456789", 0xf7c5400el;
    "12345678901234567890", 0x45e28067l; "Hello, world!", 0xc0363e43l;
    "€", 0x5b43fca5l; "€€€€€€€€€€", 0xda3c1253l ]
  |> List.iter (fun (input, expected) ->
       check (Printf.sprintf "Murmur vector %S" input) (Syscall_table.murmur3_key input = expected))

let () =
  let actual = In_channel.input_all stdin in
  parser_tests actual;
  Citation_ledger.parse actual
  |> Result.fold ~error:(fun error -> check (Citation_ledger.pp_error error) false) ~ok:(params_tests actual);
  murmur_tests ();
  match !failures with
  | [] -> print_endline "PASS target ledger, capability, regions, and independent Murmur vectors"
  | errors -> List.iter prerr_endline (List.rev errors); exit 1
