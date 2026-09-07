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
let to_string = function
  | Unsupported_prim primitive -> "Unsupported_prim: " ^ Tot_kernel.Prim.name primitive
  | Unsupported_signed_op -> "Unsupported_signed_op"
  | Call_graph_cycle names -> "Call_graph_cycle: tally requires an acyclic native call graph: " ^ String.concat " -> " names
  | Frame_overflow { fn; bytes } -> Printf.sprintf "Frame_overflow: %s (%d bytes)" fn bytes
  | Arena_overflow { words; heap_bytes } -> Printf.sprintf "Arena_overflow: %d words exceed %d heap bytes" words heap_bytes
  | Image_too_large { bytes; cap } -> Printf.sprintf "Image_too_large: %d bytes exceed %d" bytes cap
  | Unknown_syscall name -> "Unknown_syscall: " ^ name
  | Register_convention_undischarged -> "Row_unverified S18: native calls and argument passing require a ratified register convention"
  | Input_truncated { offset; need } -> Printf.sprintf "Input_truncated: offset %d needs %d bytes" offset need
  | Depth_budget_exceeded { h; d; max } -> Printf.sprintf "Depth_budget_exceeded: height %d plus bound %d exceeds %d" h d max
  | Depth_undeclared name -> "Depth_undeclared: " ^ name
  | Invalid_encoding detail -> "Invalid_encoding: " ^ detail
  | Invalid_image detail -> "Invalid_image: " ^ detail
  | Unsupported_term detail -> "Unsupported_term: " ^ detail
