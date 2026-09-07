type t
val program : Tally_cterm.Cterm.program -> (t, Emit_error.t) result
val successors : t -> Tally_cterm.Cterm.code_tag -> Tally_cterm.Cterm.code_tag list
(** Callees precede callers. *)
val order : t -> Tally_cterm.Cterm.code_tag list
