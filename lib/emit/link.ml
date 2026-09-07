type item =
  | Label of string
  | Insn of Encode.insn
  | Branch of Encode.insn * string
  | Call of Encode.insn * string

let labels items =
  let rec collect pc found = function
    | [] -> Ok (List.rev found)
    | Label name :: rest ->
        if List.mem_assoc name found then
          Error (Emit_error.Invalid_encoding ("duplicate label: " ^ name))
        else collect pc ((name, pc) :: found) rest
    | (Insn _ | Branch _ | Call _) :: rest -> collect (pc + 1) found rest
  in
  collect 0 [] items

let resolve items =
  let ( let* ) = Result.bind in
  let* table = labels items in
  let count = List.fold_left (fun n -> function Label _ -> n | Insn _ | Branch _ | Call _ -> n + 1) 0 items in
  let relative pc name =
    List.assoc_opt name table
    |> Option.fold
         ~none:(Error (Emit_error.Invalid_encoding ("unknown label: " ^ name)))
         ~some:(fun target ->
           if target < 0 || target >= count then
             Error (Emit_error.Invalid_encoding ("label outside bytecode: " ^ name))
           else Ok (target - pc - 1))
  in
  let rec link pc reversed = function
    | [] -> Ok (List.rev reversed)
    | Label _ :: rest -> link pc reversed rest
    | Insn instruction :: rest -> link (pc + 1) (instruction :: reversed) rest
    | Branch (instruction, name) :: rest ->
        let* delta = relative pc name in
        if delta < -(1 lsl 15) || delta >= 1 lsl 15 then
          Error (Emit_error.Invalid_encoding ("branch out of range: " ^ name))
        else link (pc + 1) ({ instruction with off = delta } :: reversed) rest
    | Call (instruction, name) :: rest ->
        let* delta = relative pc name in
        if Int64.of_int delta < Int64.of_int32 Int32.min_int ||
           Int64.of_int delta > Int64.of_int32 Int32.max_int then
          Error (Emit_error.Invalid_encoding ("call out of range: " ^ name))
        else link (pc + 1) ({ instruction with imm = Int32.of_int delta } :: reversed) rest
  in
  link 0 [] items
