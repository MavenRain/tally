type t =
  | Unsupported_prim of Tot_kernel.Prim.t
  | Unsupported_signed_op
  | Call_graph_cycle of string list
  | Frame_overflow of { fn : string; bytes : int }
  | Arena_overflow of { words : int; heap_bytes : int }
  | Image_too_large of { bytes : int; cap : int }
  | Unknown_syscall of string
  | Register_convention_undischarged
  | Input_truncated of { offset : int; need : int }
  | Depth_budget_exceeded of { h : int; d : int; max : int }
  | Depth_undeclared of string
  | Invalid_encoding of string
  | Invalid_image of string
  | Unsupported_term of string
val to_string : t -> string
