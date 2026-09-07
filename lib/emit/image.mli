val build : Tally_target.Target_params.t -> entry:int ->
  functions:(string * int * int) list -> code:bytes -> rodata:string ->
  (bytes, Emit_error.t) result
