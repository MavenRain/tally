type diagnostic = { global_name : string; span : string option; detail : string }
type t =
  | Cerr_open_term of diagnostic
  | Cerr_apply_erased of diagnostic
  | Cerr_host_io of diagnostic
  | Cerr_host_string of diagnostic
  | Cerr_host_json of diagnostic
  | Cerr_host_regex of diagnostic
  | Cerr_boxed_int of diagnostic
  | Cerr_effect_prim of diagnostic
  | Cerr_unary_numeral of diagnostic
  | Cerr_arena_over of diagnostic
  | Cerr_dense_tags of diagnostic
  | Cerr_unknown_global of diagnostic
  | Cerr_arity of diagnostic
  | Cerr_verify of diagnostic
  | Cerr_declaration of diagnostic
val diagnostic : ?span:string -> string -> string -> diagnostic
val render : t -> string
