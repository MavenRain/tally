type location = Register of int | Spill of int
type t
val code : Tally_cterm.Cterm.code -> t
val continuation : Tally_cterm.Cterm.kont -> t
val location : t -> Tally_cterm.Cterm.slot -> location option
val spill_words : t -> int
