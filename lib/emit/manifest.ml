type fn = { name : string; slot_start : int; slot_count : int; frame_bytes : int }

let render ~functions ~instruction_count ~image_bytes =
  let rows = List.map (fun fn ->
    Printf.sprintf "function %S slots=%d..%d frame-bytes=%d\n"
      fn.name fn.slot_start (fn.slot_start + fn.slot_count) fn.frame_bytes) functions in
  Printf.sprintf "tally-manifest 1\ninstructions %d\nimage-bytes %d\n%s"
    instruction_count image_bytes (String.concat "" rows)
