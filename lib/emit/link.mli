type item =
  | Label of string
  | Insn of Encode.insn
  | Branch of Encode.insn * string
  | Call of Encode.insn * string

val labels : item list -> ((string * int) list, Emit_error.t) result
val resolve : item list -> (Encode.insn list, Emit_error.t) result
