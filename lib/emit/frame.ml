open Tally_cterm.Cterm
module Params = Tally_target.Target_params
let ( let* ) = Result.bind
let reserve = 0
type t = { codes : (code_tag * (Regalloc.t * int)) list; konts : (kont_tag * (Regalloc.t * int)) list }
let code frames tag = List.assoc_opt tag frames.codes
let continuation frames tag = List.assoc_opt tag frames.konts
let overflow fn bytes = Error (Emit_error.Frame_overflow { fn; bytes })
let sum fn a b = if a < 0 || b < 0 || a > max_int - b then overflow fn max_int else Ok (a + b)
let divide a b = if b <= 0 then Error (Emit_error.Invalid_encoding "nonpositive layout divisor") else Ok (a / b) (* @total-accessor *)
let program params p graph =
  let word = Params.word_bytes params in
  let heap_bytes = Params.heap_bytes params in
  let* heap_words = divide heap_bytes word in
  let* () = if p.arena_words < 0 || p.arena_words > heap_words then
      Error (Emit_error.Arena_overflow { words = p.arena_words; heap_bytes }) else Ok () in
  let measure name allocation =
    let words = Regalloc.spill_words allocation in
    let* max_words = divide max_int word in
    if words > max_words then overflow name max_int else
    let bytes = words * word in
    let alignment = Params.frame_alignment params in
    if alignment <= 0 then Error (Emit_error.Invalid_encoding "invalid frame alignment") else
    let* rounded = sum name bytes (alignment - 1) in
    let* units = divide rounded alignment in
    let bytes = units * alignment in
    if bytes > Params.frame_bytes params - reserve then overflow name bytes
    else Ok (allocation, bytes) in
  let* codes = Array.fold_left (fun result item ->
    let* codes = result in let* measured = measure item.name (Regalloc.code item) in
    Ok ((item.code_id, measured) :: codes)) (Ok []) p.codes in
  let* konts = Array.fold_left (fun result item ->
    let* konts = result in
    let* measured = measure ("<kont " ^ string_of_int (kont_index item.kont_id) ^ ">") (Regalloc.continuation item) in
    Ok ((item.kont_id, measured) :: konts)) (Ok []) p.konts in
  let frames = { codes; konts } in
  let* _ = List.fold_left (fun result tag ->
    let* paths = result in
    let* definition = code_of_tag p tag |> Option.to_result ~none:(Emit_error.Unsupported_term "missing frame code") in
    let* _, own = code frames tag |> Option.to_result ~none:(Emit_error.Unsupported_term "missing frame allocation") in
    let child_bytes, child_depth, deep_bytes = List.fold_left (fun (bytes, depth, deep_bytes) child ->
      let b, d, db = Option.value (List.assoc_opt child paths) ~default:(0, 0, 0) in
      let deep_bytes = if d > depth then db else if d = depth then max deep_bytes db else deep_bytes in
      max bytes b, max depth d, deep_bytes)
      (0, 0, 0) (Callgraph.successors graph tag) in
    let* bytes = sum definition.name own child_bytes in
    let* depth = sum definition.name 1 child_depth in
    let* deep_bytes = sum definition.name own deep_bytes in
    if bytes > Params.stack_bytes params then overflow definition.name bytes
    else if depth > Params.max_native_call_depth params then overflow definition.name deep_bytes
    else Ok ((tag, (bytes, depth, deep_bytes)) :: paths)) (Ok []) (Callgraph.order graph) in
  Ok frames
