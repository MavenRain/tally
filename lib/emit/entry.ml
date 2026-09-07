let select ~name functions =
  match List.filter (fun (candidate, _, _) -> String.equal candidate name) functions with
  | [ (_, start, count) ] when start >= 0 && count > 0 -> Ok start
  | [] -> Error (Emit_error.Invalid_image ("entry function absent: " ^ name))
  | [ _ ] -> Error (Emit_error.Invalid_image "empty entry function")
  | _ :: _ :: _ -> Error (Emit_error.Invalid_image "ambiguous entry function")
