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

let diagnostic ?span global_name detail = { global_name; span; detail }

let render error =
  let name, d =
    match error with
    | Cerr_open_term d -> "Cerr_open_term", d
    | Cerr_apply_erased d -> "Cerr_apply_erased", d
    | Cerr_host_io d -> "Cerr_host_io", d
    | Cerr_host_string d -> "Cerr_host_string", d
    | Cerr_host_json d -> "Cerr_host_json", d
    | Cerr_host_regex d -> "Cerr_host_regex", d
    | Cerr_boxed_int d -> "Cerr_boxed_int", d
    | Cerr_effect_prim d -> "Cerr_effect_prim", d
    | Cerr_unary_numeral d -> "Cerr_unary_numeral", d
    | Cerr_arena_over d -> "Cerr_arena_over", d
    | Cerr_dense_tags d -> "Cerr_dense_tags", d
    | Cerr_unknown_global d -> "Cerr_unknown_global", d
    | Cerr_arity d -> "Cerr_arity", d
    | Cerr_verify d -> "Cerr_verify", d
    | Cerr_declaration d -> "Cerr_declaration", d
  in
  let location = Option.fold ~none:"" ~some:(fun s -> " at " ^ s) d.span in
  "Cerror." ^ name ^ " " ^ d.global_name ^ location ^ ": " ^ d.detail
