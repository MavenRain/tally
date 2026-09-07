open Tot_kernel
open Tally_cterm.Cterm
module Params = Tally_target.Target_params
module Syscalls = Tally_target.Syscall_table
let ( let* ) = Result.bind
type selected = { instructions : Link.item list; functions : (string * string * int) list; rodata : string }
let unsupported text = Error (Emit_error.Unsupported_term text)
let rec needs_convention body =
  List.exists (fun (_, rhs) -> match rhs with
    | RCallKnown _ | RApply _ | RMkClo _ | RMkKont _ -> true
    | RAtom _ | RMkCon _ | RProj _ | RPrim _ | RSyscall _ -> false) body.binds
  || match body.tail with
     | TApply _ | TResume _ -> true
     | TSwitch (_, branches, default) -> List.exists (fun (_, b) -> needs_convention b) branches || needs_convention default
     | TRet _ | TTrap _ -> false
let width_bits = function Word.W8 -> 8 | Word.W16 -> 16 | Word.W32 -> 32 | Word.W64 -> 64

let program params p =
  let* () = Tally_cterm.Verify.program p
    |> Result.map_error (fun error -> Emit_error.Unsupported_term (Tally_cterm.Cerror.render error)) in
  let* graph = Callgraph.program p in
  let* frames = Frame.program params p graph in
  let requires = Array.length p.konts <> 0 || Array.exists (fun code ->
    code.arity <> 0 || code.captures <> 0 || needs_convention code.body) p.codes in
  let* () = if requires then Error Emit_error.Register_convention_undischarged else Ok () in
  let* entry = code_of_tag p p.entry |> Option.to_result ~none:(Emit_error.Unsupported_term "entry code is absent") in
  let* allocation, frame_bytes = Frame.code frames p.entry
    |> Option.to_result ~none:(Emit_error.Unsupported_term "entry frame is absent") in
  let output = ref [] in
  let serial = ref 0 in
  let emit item = output := item :: !output in
  let label () = let name = "$leaf." ^ string_of_int !serial in incr serial; name in
  let mark name = emit (Link.Label name) in
  let make ?(dst = 0) ?(src = 0) ?(off = 0) ?(imm = 0l) opcode = Encode.{ opcode = opcode params; dst; src; off; imm } in
  let instruction ?dst ?src ?off ?imm opcode = emit (Link.Insn (make ?dst ?src ?off ?imm opcode)) in
  let branch ?dst ?src ?imm opcode target = emit (Link.Branch (make ?dst ?src ?imm opcode, target)) in
  let jump target = branch Params.op_ja target in
  let result = Params.return_register params in
  let lhs = 3 in
  let rhs_register = 4 in
  let scratch = 5 in
  let fp = Params.frame_pointer_register params in
  let immediate dst value =
    let low = Int64.to_int32 value in
    if Int64.equal value (Int64.of_int32 low) then instruction Params.op_mov64_imm ~dst ~imm:low
    else (
      instruction Params.op_mov32_imm ~dst ~imm:low;
      instruction Params.op_hor64_imm ~dst ~imm:(Int64.to_int32 (Int64.shift_right_logical value 32))) in
  let move dst src = if dst <> src then instruction Params.op_mov64_reg ~dst ~src in
  let location slot = Regalloc.location allocation slot
    |> Option.to_result ~none:(Emit_error.Unsupported_term ("local has no allocation: " ^ string_of_int (slot_index slot))) in
  let load_local dst slot =
    let* located = location slot in
    (match located with
     | Regalloc.Register src -> move dst src
     | Regalloc.Spill index -> instruction Params.op_ldx64 ~dst ~src:fp ~off:(index * Params.word_bytes params));
    Ok () in
  let store slot =
    let* located = location slot in
    (match located with
     | Regalloc.Register dst -> move dst result
     | Regalloc.Spill index -> instruction Params.op_stx64 ~dst:fp ~src:result ~off:(index * Params.word_bytes params));
    Ok () in
  let constructors = ref [] in
  let reserved = ref [] in
  let collision = ref None in
  (* Tags 0, 1 and 2 are reserved for the boolean and comparison results the
     word primitives materialise. Two constructor names of one reserved class
     would emit two identical JEQ_IMM tests, so the first arm would win and the
     second would be dead code. Record the pair and reject the program. *)
  let reserve tag name =
    List.find_opt (fun (stored, held) -> held = tag && not (String.equal stored name)) !reserved
    |> Option.iter (fun (stored, _) -> collision := Some (stored, name));
    if not (List.mem_assoc name !reserved) then reserved := (name, tag) :: !reserved;
    tag in
  let constructor ctor =
    let name = ctor_name ctor in
    match name with
    | "false" | "lt" | "unit" -> reserve 0 name
    | "true" | "eq" -> reserve 1 name
    | "gt" -> reserve 2 name
    | _ ->
        List.assoc_opt name !constructors |> Option.fold
          ~none:(fun () -> let tag = List.length !constructors + 3 in constructors := (name, tag) :: !constructors; tag)
          ~some:(fun tag () -> tag) |> fun resolve -> resolve () in
  let string_entry text = List.find_opt (fun (stored, _, _) -> String.equal text stored) p.strings
    |> Option.to_result ~none:(Emit_error.Unsupported_term "string has no read-only layout") in
  let load dst = function
    | ALocal slot -> load_local dst slot
    | ALit (LWord (width, sign, bits)) -> immediate dst (Word.mk width sign bits).bits; Ok ()
    | ALit (LStr text) -> let* _, offset, _ = string_entry text in
        immediate dst (Int64.add (Params.mm_rodata_start params) (Int64.of_int offset)); Ok ()
    | ALit (LInt _) -> unsupported "boxed integers are not an emitter value"
    | AGlobal ctor -> immediate dst (Int64.of_int (constructor ctor)); Ok ()
    | AErased -> immediate dst 0L; Ok () in
  let mask width register =
    match width with
    | Word.W64 -> ()
    | Word.W8 | Word.W16 | Word.W32 ->
        let shift = Params.word_bits params - width_bits width in
        instruction Params.op_lsh64_imm ~dst:register ~imm:(Int32.of_int shift);
        instruction Params.op_rsh64_imm ~dst:register ~imm:(Int32.of_int shift) in
  let sign_extend width register =
    match width with
    | Word.W64 -> ()
    | Word.W8 | Word.W16 | Word.W32 ->
        let shift = Params.word_bits params - width_bits width in
        instruction Params.op_lsh64_imm ~dst:register ~imm:(Int32.of_int shift);
        instruction Params.op_arsh64_imm ~dst:register ~imm:(Int32.of_int shift) in
  let arithmetic width opcode a b =
    let* () = load lhs a in let* () = load rhs_register b in
    move result lhs;
    instruction opcode ~dst:result ~src:rhs_register;
    mask width result;
    Ok () in
  let division width sign remainder a b =
    let* () = load lhs a in let* () = load rhs_register b in
    let zero = label () in let compute = label () in let finish = label () in
    branch Params.op_jeq_imm ~dst:rhs_register zero;
    (match sign with
     | Word.Unsigned -> ()
     | Word.Signed ->
         sign_extend width lhs; sign_extend width rhs_register;
         immediate scratch Int64.min_int;
         branch Params.op_jne_reg ~dst:lhs ~src:scratch compute;
         branch Params.op_jne_imm ~dst:rhs_register ~imm:(-1l) compute;
         if remainder then immediate result 0L else move result lhs;
         jump finish);
    mark compute;
    move result lhs;
    let opcode = match sign with
      | Word.Unsigned -> if remainder then Params.op_urem64_reg else Params.op_udiv64_reg
      | Word.Signed -> if remainder then Params.op_srem64_reg else Params.op_sdiv64_reg in
    instruction opcode ~dst:result ~src:rhs_register;
    jump finish;
    mark zero;
    if remainder then move result lhs else immediate result 0L;
    mark finish;
    mask width result;
    Ok () in
  let shift width sign right a b =
    let* () = load lhs a in let* () = load rhs_register b in
    let zero = label () in let finish = label () in
    branch Params.op_jge_imm ~dst:rhs_register ~imm:(Int32.of_int (width_bits width)) zero;
    move result lhs;
    let opcode = if right then
      match sign with
      | Word.Unsigned -> Params.op_rsh64_reg
      | Word.Signed -> sign_extend width result; Params.op_arsh64_reg
      else Params.op_lsh64_reg in
    instruction opcode ~dst:result ~src:rhs_register;
    jump finish;
    mark zero; immediate result 0L;
    mark finish; mask width result;
    Ok () in
  let comparison width sign equality a b =
    let* () = load lhs a in let* () = load rhs_register b in
    let equal = label () in let greater = label () in let finish = label () in
    (match sign with Word.Unsigned -> () | Word.Signed -> sign_extend width lhs; sign_extend width rhs_register);
    branch Params.op_jeq_reg ~dst:lhs ~src:rhs_register equal;
    if equality then immediate result (Int64.of_int (constructor (ctor "false")))
    else (
      let opcode = match sign with Word.Unsigned -> Params.op_jgt_reg | Word.Signed -> Params.op_jsgt_reg in
      branch opcode ~dst:lhs ~src:rhs_register greater;
      immediate result (Int64.of_int (constructor (ctor "lt"))));
    jump finish;
    mark greater;
    if not equality then immediate result (Int64.of_int (constructor (ctor "gt")));
    jump finish;
    mark equal;
    immediate result (Int64.of_int (constructor (ctor (if equality then "true" else "eq"))));
    mark finish;
    Ok () in
  let primitive primitive arguments =
    let binary operation = match arguments with
      | [a; b] -> operation a b
      | [] | [_] | _ :: _ :: _ :: _ -> Error (Emit_error.Unsupported_prim primitive) in
    match primitive with
    | Prim.Word_add (width, _) -> binary (arithmetic width Params.op_add64_reg)
    | Prim.Word_sub (width, _) -> binary (arithmetic width Params.op_sub64_reg)
    | Prim.Word_mul (width, _) -> binary (arithmetic width Params.op_lmul64_reg)
    | Prim.Word_and (width, _) -> binary (arithmetic width Params.op_and64_reg)
    | Prim.Word_or (width, _) -> binary (arithmetic width Params.op_or64_reg)
    | Prim.Word_xor (width, _) -> binary (arithmetic width Params.op_xor64_reg)
    | Prim.Word_not (width, _) ->
        (match arguments with
         | [a] -> let* () = load result a in instruction Params.op_xor64_imm ~dst:result ~imm:(-1l); mask width result; Ok ()
         | [] | _ :: _ :: _ -> Error (Emit_error.Unsupported_prim primitive))
    | Prim.Word_div (width, sign) -> binary (division width sign false)
    | Prim.Word_mod (width, sign) -> binary (division width sign true)
    | Prim.Word_shl (width, sign) -> binary (shift width sign false)
    | Prim.Word_shr (width, sign) -> binary (shift width sign true)
    | Prim.Word_eq (width, sign) -> binary (comparison width sign true)
    | Prim.Word_compare (width, sign) -> binary (comparison width sign false)
    | Prim.Word_to_string _ | Prim.Read_stdin | Prim.Print_line | Prim.Exit_with | Prim.Get_env
    | Prim.Read_file | Prim.Write_file | Prim.Argv | Prim.Proc_run | Prim.String_concat
    | Prim.String_length | Prim.String_eq | Prim.String_contains | Prim.String_slice
    | Prim.String_split | Prim.String_to_int | Prim.Int_to_string | Prim.Json_parse
    | Prim.Json_serialize | Prim.Regex_test | Prim.Regex_match | Prim.Int_add | Prim.Int_sub
    | Prim.Int_eq | Prim.Int_compare | Prim.Pure_div | Prim.Bind_div | Prim.Pure_io
    | Prim.Bind_io | Prim.Lift_io -> Error (Emit_error.Unsupported_prim primitive) in
  let string_value strings = function
    | ALit (LStr text) -> Some text
    | ALocal slot -> List.assoc_opt slot strings
    | AGlobal _ | ALit (LInt _) | ALit (LWord _) | AErased -> None in
  let expression strings = function
    | RAtom atom -> load result atom
    | RPrim (prim, arguments) -> primitive prim arguments
    | RMkCon (ctor, []) -> immediate result (Int64.of_int (constructor ctor)); Ok ()
    | RSyscall (Syscall.Sol_log, [argument]) ->
        let* text = string_value strings argument |> Option.to_result
          ~none:(Emit_error.Unsupported_term "logging requires a static string value") in
        let* _, offset, length = string_entry text in
        let* key = Syscalls.key (Syscalls.of_params params) "sol_log_"
          |> Result.map_error (fun (Syscalls.Unknown_syscall name) -> Emit_error.Unknown_syscall name) in
        immediate (Params.syscall_arg_first params) (Int64.add (Params.mm_rodata_start params) (Int64.of_int offset));
        immediate (Params.syscall_arg_second params) (Int64.of_int length);
        instruction Params.op_syscall ~imm:key;
        immediate result 0L;
        Ok ()
    | RSyscall (Syscall.Sol_log, ([] | _ :: _ :: _)) -> unsupported "logging syscall requires one argument"
    | RCallKnown _ | RApply _ | RMkClo _ | RMkKont _ -> Error Emit_error.Register_convention_undischarged
    | RMkCon (_, _ :: _) | RProj _ -> unsupported "constructor payloads require the allocation backend" in
  let finish () =
    instruction Params.op_add64_imm ~dst:fp ~imm:(Int32.of_int frame_bytes);
    instruction Params.op_return in
  let rec block strings body =
    let* strings = List.fold_left (fun outcome (slot, rhs) ->
      let* strings = outcome in
      let* () = expression strings rhs in
      let* () = store slot in
      let literal = match rhs with
        | RAtom atom -> string_value strings atom
        | RMkClo _ | RMkKont _ | RMkCon _ | RProj _ | RPrim _ | RSyscall _ | RCallKnown _ | RApply _ -> None in
      Ok (Option.fold ~none:strings ~some:(fun text -> (slot, text) :: strings) literal)) (Ok strings) body.binds in
    match body.tail with
    | TRet atom -> let* () = load result atom in finish (); Ok ()
    | TApply _ | TResume _ -> Error Emit_error.Register_convention_undischarged
    | TTrap Trap_impossible_ctor ->
        (* Invalid verified-source control flow produces a runtime memory
           fault rather than silently returning a successful value. *)
        immediate result 0L;
        instruction Params.op_ldx64 ~dst:result ~src:result;
        finish (); Ok ()
    | TSwitch (atom, branches, default) ->
        let* () = load result atom in
        let targets = List.map (fun (ctor, body) -> ctor, body, label ()) branches in
        List.iter (fun (ctor, _, target) -> branch Params.op_jeq_imm ~dst:result ~imm:(Int32.of_int (constructor ctor)) target) targets;
        let* () = block strings default in
        List.fold_left (fun outcome (_, body, target) -> let* () = outcome in mark target; block strings body) (Ok ()) targets in
  let entry_label = "$code." ^ string_of_int (code_index entry.code_id) in
  mark entry_label;
  instruction Params.op_add64_imm ~dst:fp ~imm:(Int32.of_int (-frame_bytes));
  let* () = block [] entry.body in
  let* () = Option.fold ~none:(Ok ())
    ~some:(fun (stored, name) -> Error (Emit_error.Unsupported_term
      ("constructor name collides with a reserved tag: " ^ stored ^ " and " ^ name)))
    !collision in
  Ok { instructions = List.rev !output; functions = [entry.name, entry_label, frame_bytes]; rodata = p.rodata }
