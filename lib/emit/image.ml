module Params = Tally_target.Target_params
let ( let* ) = Result.bind

type section = {
  name : string; kind : int; flags : int; address : int64;
  offset : int; size : int; link : int; info : int; alignment : int; entsize : int;
}

let strings names =
  let buffer = Buffer.create 128 in
  Buffer.add_char buffer '\000';
  let offsets = List.map (fun name ->
    let offset = Buffer.length buffer in
    Buffer.add_string buffer name;
    Buffer.add_char buffer '\000';
    name, offset) names in
  Buffer.contents buffer, offsets

let build params ~entry ~functions ~code ~rodata =
  let code_size = Bytes.length code in
  let cap = Params.image_cap_bytes params in
  let word = Params.insn_size params in
  let too_large bytes = Error (Emit_error.Image_too_large { bytes; cap }) in
  let bounded_sum values = List.fold_left (fun result value ->
    let* total = result in
    if value < 0 then Error (Emit_error.Invalid_image "negative image component")
    else if value > cap - total then too_large (cap + 1)
    else Ok (total + value)) (Ok 0) values in
  if word <> 8 || code_size = 0 || code_size land 7 <> 0 then
    Error (Emit_error.Invalid_image "bytecode must contain complete instructions")
  else if List.exists (fun (name, _, count) ->
    String.length name = 0 || String.length name >= 255 || String.contains name '\000' || count <= 0) functions then
    Error (Emit_error.Invalid_image "invalid function name or size")
  else
    let* end_slot = List.fold_left (fun result (_, start, count) ->
      let* expected = result in
      if start <> expected || count > (code_size lsr 3) - expected then
        Error (Emit_error.Invalid_image "function symbols must cover contiguous bytecode")
      else Ok (start + count)) (Ok 0) functions in
    if end_slot <> code_size lsr 3 || not (List.exists (fun (_, start, _) -> start = entry) functions) then
      Error (Emit_error.Invalid_image "entry or function coverage is invalid")
    else
      let names = List.map (fun (name, _, _) -> name) functions in
      if List.length (List.sort_uniq String.compare names) <> List.length names then
        Error (Emit_error.Invalid_image "duplicate function name")
      else
        let* _ = bounded_sum [code_size; String.length rodata; List.length functions * Params.symbol_size params] in
        let dynstr, symbol_offsets = strings names in
        let shstr, section_offsets = strings [".text"; ".rodata"; ".dynsym"; ".dynstr"; ".shstrtab"] in
        let align n = (n + 7) land (lnot 7) in
        let text_offset = Params.e_ehsize params + Params.phdr_count params * Params.e_phentsize params in
        let* rodata_offset = bounded_sum [text_offset; code_size] in
        let* rodata_end = bounded_sum [rodata_offset; String.length rodata] in
        let symbol_offset = align rodata_end in
        let symbol_bytes = List.length functions * Params.symbol_size params in
        let* dynstr_offset = bounded_sum [symbol_offset; symbol_bytes] in
        let* shstr_offset = bounded_sum [dynstr_offset; String.length dynstr] in
        let* shstr_end = bounded_sum [shstr_offset; String.length shstr] in
        let sections_offset = align shstr_end in
        let section_count = 6 in
        let* total = bounded_sum [sections_offset; section_count * Params.e_shentsize params] in
        let buffer = Buffer.create total in
        let u16 = Buffer.add_int16_le buffer in
        let u32 n = Buffer.add_int32_le buffer (Int32.of_int n) in
        let u64 = Buffer.add_int64_le buffer in
        let size n = u64 (Int64.of_int n) in
        let padding target =
          if Buffer.length buffer > target then Error (Emit_error.Invalid_image "overlapping image components")
          else (Buffer.add_string buffer (String.make (target - Buffer.length buffer) '\000'); Ok ()) in
        Buffer.add_string buffer (Params.elf_magic params);
        List.iter (Buffer.add_uint8 buffer)
          [Params.ei_class_64 params; Params.ei_data_lsb params; Params.elf_version params;
           Params.elf_osabi params; Params.elf_abi_version params];
        let* () = padding (Params.elf_ident_size params) in
        u16 (Params.e_type_dyn params); u16 (Params.e_machine_sbpf params);
        u32 (Params.elf_version params);
        u64 (Int64.add (Params.mm_bytecode_start params) (Int64.of_int (entry * word)));
        size (Params.e_phoff params); size sections_offset; u32 (Params.e_flags_v3 params);
        u16 (Params.e_ehsize params); u16 (Params.e_phentsize params); u16 (Params.phdr_count params);
        u16 (Params.e_shentsize params); u16 section_count; u16 5;
        let header kind flags offset address filesz memsz =
          u32 kind; u32 flags; size offset; u64 address; u64 address;
          size filesz; size memsz; size word in
        header (Params.pt_load params) (Params.pf_x params) text_offset (Params.mm_bytecode_start params) code_size code_size;
        header (Params.pt_load params) (Params.pf_r params) rodata_offset (Params.mm_rodata_start params) (String.length rodata) (String.length rodata);
        header (Params.pt_gnu_stack params) (Params.pf_r params lor Params.pf_w params) text_offset (Params.mm_stack_start params) 0 (Params.stack_bytes params);
        header (Params.pt_load params) (Params.pf_r params lor Params.pf_w params) text_offset (Params.mm_heap_start params) 0 (Params.heap_bytes params);
        header (Params.pt_null params) 0 symbol_offset (Params.dynsym_sentinel_vaddr params) symbol_bytes symbol_bytes;
        let* () = padding text_offset in
        Buffer.add_bytes buffer code;
        Buffer.add_string buffer rodata;
        let* () = padding symbol_offset in
        let* () = List.fold_left (fun result (name, start, count) ->
          let* () = result in
          let* name_offset = List.assoc_opt name symbol_offsets
            |> Option.to_result ~none:(Emit_error.Invalid_image "missing symbol name") in
          u32 name_offset;
          Buffer.add_uint8 buffer (Params.stt_func params);
          Buffer.add_uint8 buffer 0; u16 1;
          u64 (Int64.add (Params.mm_bytecode_start params) (Int64.of_int (start * word)));
          size (count * word); Ok ()) (Ok ()) functions in
        let* () = padding dynstr_offset in
        Buffer.add_string buffer dynstr; Buffer.add_string buffer shstr;
        let* () = padding sections_offset in
        let section name kind flags address offset size link info alignment entsize =
          { name; kind; flags; address; offset; size; link; info; alignment; entsize } in
        let sections = [
          section "" (Params.sht_null params) 0 0L 0 0 0 0 0 0;
          section ".text" (Params.sht_progbits params) (Params.shf_alloc params lor Params.shf_execinstr params) (Params.mm_bytecode_start params) text_offset code_size 0 0 word 0;
          section ".rodata" (Params.sht_progbits params) (Params.shf_alloc params) (Params.mm_rodata_start params) rodata_offset (String.length rodata) 0 0 word 0;
          section ".dynsym" (Params.sht_dynsym params) 0 0L symbol_offset symbol_bytes 4 (List.length functions) word (Params.symbol_size params);
          section ".dynstr" (Params.sht_strtab params) 0 0L dynstr_offset (String.length dynstr) 0 0 1 0;
          section ".shstrtab" (Params.sht_strtab params) 0 0L shstr_offset (String.length shstr) 0 0 1 0;
        ] in
        List.iter (fun section ->
          u32 (Option.value (List.assoc_opt section.name section_offsets) ~default:0);
          u32 section.kind; size section.flags; u64 section.address;
          size section.offset; size section.size; u32 section.link; u32 section.info;
          size section.alignment; size section.entsize) sections;
        if Buffer.length buffer <> total then Error (Emit_error.Invalid_image "image size disagreement")
        else Ok (Bytes.of_string (Buffer.contents buffer))
