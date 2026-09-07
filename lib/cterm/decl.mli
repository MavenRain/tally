(** Source declarations are data. Target checks belong to the emitter. *)
type t
val parse : string -> (t, Cerror.t) result
val source : string -> (string * t, Cerror.t) result
val entry_height : t -> int
val depth_bound : t -> string -> int option
val is_explicit : t -> bool
