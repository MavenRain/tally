type insn = { opcode : int; dst : int; src : int; off : int; imm : int32 }

val encode : Tally_target.Target_params.t -> insn list -> (bytes, Emit_error.t) result
