(** Compute flat frames and the static allocation footprint. [arena_limit],
    when supplied by the caller, is measured in words. No target limit is
    selected by this pass. *)
val program : ?arena_limit:int -> Cterm.program -> (Cterm.program, Cerror.t) result
