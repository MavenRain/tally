type t
val of_params : Target_params.t -> t
val bytecode : t -> int64
val rodata : t -> int64
val stack : t -> int64
val heap : t -> int64
val input : t -> int64
