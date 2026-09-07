type fn = { name : string; slot_start : int; slot_count : int; frame_bytes : int }
val render : functions:fn list -> instruction_count:int -> image_bytes:int -> string
