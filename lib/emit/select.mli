type selected = {
  instructions : Link.item list;
  functions : (string * string * int) list;
  rodata : string;
}
val program : Tally_target.Target_params.t -> Tally_cterm.Cterm.program -> (selected, Emit_error.t) result
