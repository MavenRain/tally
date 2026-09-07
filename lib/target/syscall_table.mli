type t
type lookup_error = Unknown_syscall of string
val of_params : Target_params.t -> t
val names : t -> string list
val key : t -> string -> (int32, lookup_error) result
(** Standard seed-zero MurmurHash over the exact input bytes, without a trailing
    terminator. The target's syscall table requires citation-checked params. *)
val murmur3_key : string -> int32
