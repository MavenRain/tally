type t
val reserve : int
val program : Tally_target.Target_params.t -> Tally_cterm.Cterm.program -> Callgraph.t -> (t, Emit_error.t) result
val code : t -> Tally_cterm.Cterm.code_tag -> (Regalloc.t * int) option
val continuation : t -> Tally_cterm.Cterm.kont_tag -> (Regalloc.t * int) option
