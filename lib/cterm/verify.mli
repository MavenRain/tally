type counts = {
  dense : int;
  konts : int;
  switch_defaults : int;
  callknown_edges : int;
}
val program : Cterm.program -> (unit, Cerror.t) result
(** Rederive counters from the program. Call [program] before reporting
    these as verified facts. *)
val summary : Cterm.program -> counts
