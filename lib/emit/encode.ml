type insn = { opcode : int; dst : int; src : int; off : int; imm : int32 }

let encode params instructions =
  let size = Tally_target.Target_params.insn_size params in
  let count = List.length instructions in
  if size <> 8 || count > Sys.max_string_length lsr 3 then
    Error (Emit_error.Invalid_encoding "instruction buffer size")
  else
    let buffer = Buffer.create (count * size) in
    let rec write = function
      | [] -> Ok (Bytes.of_string (Buffer.contents buffer))
      | instruction :: rest ->
          if instruction.opcode < 0 || instruction.opcode > 255 ||
             instruction.dst < 0 || instruction.dst > 15 ||
             instruction.src < 0 || instruction.src > 15 ||
             instruction.off < -(1 lsl 15) || instruction.off >= 1 lsl 15 then
            Error (Emit_error.Invalid_encoding "instruction field out of range")
          else (
            Buffer.add_uint8 buffer instruction.opcode;
            Buffer.add_uint8 buffer (instruction.dst lor (instruction.src lsl 4));
            Buffer.add_int16_le buffer instruction.off;
            Buffer.add_int32_le buffer instruction.imm;
            write rest)
    in
    write instructions
