(** A parsed ledger, including explicit negative and unresolved evidence. *)
type t

type parse_error =
  | No_table
  | Malformed_table of { line : int; detail : string }
  | Duplicate_row of { line : int; id : string }
  | Invalid_status of { line : int; id : string; status : string }

val parse : string -> (t, parse_error) result

(** True only for a positively VERIFIED fact with evidence. A refuted fact,
    unresolved fact, or absent row returns false. *)
val verified : t -> string -> bool
val rows : t -> string list
val pp_error : parse_error -> string
