(* All numeric target facts enter through this citation-checked capability. *)
type t = Params of Citation_ledger.t
type build_error = Row_unverified of string | Unknown_target of string

let required_rows =
  [ "C3"; "C4"; "C5"; "C7"; "C8"; "C9"; "C10"; "C12";
    "F-SPEC"; "F-EMIT"; "F-EMIT-SHIFT";
    "S1"; "S2"; "S3"; "S4"; "S5"; "S6"; "S7";
    "S15"; "S16"; "S17" ]

let of_ledger ledger target =
  if not (String.equal target "sbpf-v3") then Error (Unknown_target target)
  else
    Option.fold ~none:(Ok (Params ledger))
      ~some:(fun row -> Error (Row_unverified row))
      (List.find_opt (fun row -> not (Citation_ledger.verified ledger row)) required_rows)

(* The argument convention is exactly the ledger's own S18 cell, which the
   plan's third open question makes the single discharge point. Citation_ledger
   owns which status tokens count, so a refuted or unresolved cell keeps this
   capability closed. Single-function builds can use the target while it stays
   closed. *)
let require_calling_convention (Params ledger) =
  if Citation_ledger.verified ledger "S18" then Ok () else Error (Row_unverified "S18")

(* Resource budgets and region bases: the consumed ledger rows carry the pins. *)
let frame_bytes = 4096 (* ledger: C7 *)
let max_native_call_depth = 64 (* ledger: C7 *)
let heap_bytes = 32768 (* ledger: C8 *)
let heap_max_bytes = 262144 (* ledger: C8 *)
let cu_budget = 200000 (* ledger: C9 *)
let tx_byte_cap = 1232 (* ledger: C10 *)
let image_cap_bytes = 10485760 (* ledger: C12 *)
let insn_size = 8 (* ledger: S17 *)
let e_flags_v3 = 3 (* ledger: S4 *)
let e_type_dyn = 3 (* ledger: S4 *)
let e_machine_sbpf = 263 (* ledger: S4 *)
let ei_class_64 = 2 (* ledger: S4 *)
let ei_data_lsb = 1 (* ledger: S4 *)
let e_phoff = 64 (* ledger: S4 *)
let e_phentsize = 56 (* ledger: S4 *)
let phdr_count = 5 (* ledger: S5 *)
let syscall_base_cost = 100 (* ledger: S15 *)
let invoke_units = 1000 (* ledger: S15 *)
let cpi_bytes_per_unit = 250 (* ledger: S15 *)
let frame_alignment = 64 (* ledger: S3 *)
let word_bytes = 8 (* ledger: S17 *)
let word_bits = 64 (* ledger: S17 *)
let register_nibble_bits = 4 (* ledger: S17 *)
let return_register = 0 (* ledger: S17 *)
let frame_pointer_register = 10 (* ledger: S3 *)
let max_source_register = 10 (* ledger: S3 *)
let max_destination_register = 9 (* ledger: S3 *)
(* The bpf-to-bpf input register is an S18 fact, and entry fact three keeps
   every S18 constant out of Stage C source, so no entry_input_register is
   defined here. The five registers below are the SYSCALL half that row S18
   records as already pinned, at the sbpf interpreter site row S1 cites. *)
let syscall_arg_first = 1 (* ledger: S1 *)
let syscall_arg_second = 2 (* ledger: S1 *)
let syscall_arg_third = 3 (* ledger: S1 *)
let syscall_arg_fourth = 4 (* ledger: S1 *)
let syscall_arg_fifth = 5 (* ledger: S1 *)
let stack_bytes = frame_bytes * max_native_call_depth (* ledger: C7 *)
let region_size = 4294967296L (* ledger: S2 *)
let mm_bytecode_start = 0L (* ledger: S2 *)
let mm_rodata_start = 4294967296L (* ledger: S2 *)
let mm_stack_start = 8589934592L (* ledger: S2 *)
let mm_heap_start = 12884901888L (* ledger: S2 *)
let mm_input_start = 17179869184L (* ledger: S2 *)
let dynsym_sentinel_vaddr = -4294967296L (* ledger: S5 *)
let e_ehsize = 64 (* ledger: S4 *)
let e_shentsize = 64 (* ledger: S4 *)
let elf_version = 1 (* ledger: S4 *)
let elf_osabi = 0 (* ledger: S4 *)
let elf_abi_version = 0 (* ledger: S4 *)
let elf_half_bytes = 2 (* ledger: S4 *)
let elf_word_bytes = 4 (* ledger: S4 *)
let elf_xword_bytes = 8 (* ledger: S4 *)
let elf_ident_size = 16 (* ledger: S4 *)
let pt_null = 0 (* ledger: S5 *)
let pt_load = 1 (* ledger: S5 *)
let pt_gnu_stack = 1685382481 (* ledger: S5 *)
let pf_x = 1 (* ledger: S5 *)
let pf_w = 2 (* ledger: S5 *)
let pf_r = 4 (* ledger: S5 *)
let stt_func = 2 (* ledger: S5 *)
let symbol_size = 24 (* ledger: S5 *)
let sht_null = 0 (* ledger: S5 *)
let sht_progbits = 1 (* ledger: S5 *)
let sht_strtab = 3 (* ledger: S5 *)
let sht_dynsym = 11 (* ledger: S5 *)
let shf_alloc = 2 (* ledger: S5 *)
let shf_execinstr = 4 (* ledger: S5 *)
let shn_undef = 0 (* ledger: S5 *)
let off_ei_class = 4 (* ledger: S4 *)
let off_ei_data = 5 (* ledger: S4 *)
let off_ei_version = 6 (* ledger: S4 *)
let off_ei_osabi = 7 (* ledger: S4 *)
let off_ei_abiversion = 8 (* ledger: S4 *)
let off_e_type = 16 (* ledger: S4 *)
let off_e_machine = 18 (* ledger: S4 *)
let off_e_version = 20 (* ledger: S4 *)
let off_e_entry = 24 (* ledger: S4 *)
let off_e_phoff = 32 (* ledger: S4 *)
let off_e_shoff = 40 (* ledger: S4 *)
let off_e_flags = 48 (* ledger: S4 *)
let off_e_ehsize = 52 (* ledger: S4 *)
let off_e_phentsize = 54 (* ledger: S4 *)
let off_e_phnum = 56 (* ledger: S4 *)
let off_e_shentsize = 58 (* ledger: S4 *)
let off_e_shnum = 60 (* ledger: S4 *)
let off_e_shstrndx = 62 (* ledger: S4 *)
let off_p_type = 0 (* ledger: S5 *)
let off_p_flags = 4 (* ledger: S5 *)
let off_p_offset = 8 (* ledger: S5 *)
let off_p_vaddr = 16 (* ledger: S5 *)
let off_p_paddr = 24 (* ledger: S5 *)
let off_p_filesz = 32 (* ledger: S5 *)
let off_p_memsz = 40 (* ledger: S5 *)
let off_p_align = 48 (* ledger: S5 *)
let off_sh_name = 0 (* ledger: S5 *)
let off_sh_type = 4 (* ledger: S5 *)
let off_sh_flags = 8 (* ledger: S5 *)
let off_sh_addr = 16 (* ledger: S5 *)
let off_sh_offset = 24 (* ledger: S5 *)
let off_sh_size = 32 (* ledger: S5 *)
let off_sh_link = 40 (* ledger: S5 *)
let off_sh_info = 44 (* ledger: S5 *)
let off_sh_addralign = 48 (* ledger: S5 *)
let off_sh_entsize = 56 (* ledger: S5 *)
let off_st_name = 0 (* ledger: S5 *)
let off_st_info = 4 (* ledger: S5 *)
let off_st_other = 5 (* ledger: S5 *)
let off_st_shndx = 6 (* ledger: S5 *)
let off_st_value = 8 (* ledger: S5 *)
let off_st_size = 16 (* ledger: S5 *)
let op_ld_1b_reg = 44 (* ledger: S6 *)
let op_ld_2b_reg = 60 (* ledger: S6 *)
let op_ld_4b_reg = 140 (* ledger: S6 *)
let op_ld_8b_reg = 156 (* ledger: S6 *)
let op_st_1b_imm = 39 (* ledger: S6 *)
let op_st_2b_imm = 55 (* ledger: S6 *)
let op_st_4b_imm = 135 (* ledger: S6 *)
let op_st_8b_imm = 151 (* ledger: S6 *)
let op_st_1b_reg = 47 (* ledger: S6 *)
let op_st_2b_reg = 63 (* ledger: S6 *)
let op_st_4b_reg = 143 (* ledger: S6 *)
let op_st_8b_reg = 159 (* ledger: S6 *)
let op_add32_imm = 4 (* ledger: S6 *)
let op_add32_reg = 12 (* ledger: S6 *)
let op_sub32_imm = 20 (* ledger: S6 *)
let op_sub32_reg = 28 (* ledger: S6 *)
let op_or32_imm = 68 (* ledger: S6 *)
let op_or32_reg = 76 (* ledger: S6 *)
let op_and32_imm = 84 (* ledger: S6 *)
let op_and32_reg = 92 (* ledger: S6 *)
let op_lsh32_imm = 100 (* ledger: S6 *)
let op_lsh32_reg = 108 (* ledger: S6 *)
let op_rsh32_imm = 116 (* ledger: S6 *)
let op_rsh32_reg = 124 (* ledger: S6 *)
let op_xor32_imm = 164 (* ledger: S6 *)
let op_xor32_reg = 172 (* ledger: S6 *)
let op_mov32_imm = 180 (* ledger: S6 *)
let op_mov32_reg = 188 (* ledger: S6 *)
let op_arsh32_imm = 196 (* ledger: S6 *)
let op_arsh32_reg = 204 (* ledger: S6 *)
let op_lmul32_imm = 134 (* ledger: S6 *)
let op_lmul32_reg = 142 (* ledger: S6 *)
let op_udiv32_imm = 70 (* ledger: S6 *)
let op_udiv32_reg = 78 (* ledger: S6 *)
let op_urem32_imm = 102 (* ledger: S6 *)
let op_urem32_reg = 110 (* ledger: S6 *)
let op_sdiv32_imm = 198 (* ledger: S6 *)
let op_sdiv32_reg = 206 (* ledger: S6 *)
let op_srem32_imm = 230 (* ledger: S6 *)
let op_srem32_reg = 238 (* ledger: S6 *)
let op_add64_imm = 7 (* ledger: S6 *)
let op_add64_reg = 15 (* ledger: S6 *)
let op_sub64_imm = 23 (* ledger: S6 *)
let op_sub64_reg = 31 (* ledger: S6 *)
let op_or64_imm = 71 (* ledger: S6 *)
let op_or64_reg = 79 (* ledger: S6 *)
let op_and64_imm = 87 (* ledger: S6 *)
let op_and64_reg = 95 (* ledger: S6 *)
let op_lsh64_imm = 103 (* ledger: S6 *)
let op_lsh64_reg = 111 (* ledger: S6 *)
let op_rsh64_imm = 119 (* ledger: S6 *)
let op_rsh64_reg = 127 (* ledger: S6 *)
let op_xor64_imm = 167 (* ledger: S6 *)
let op_xor64_reg = 175 (* ledger: S6 *)
let op_mov64_imm = 183 (* ledger: S6 *)
let op_mov64_reg = 191 (* ledger: S6 *)
let op_arsh64_imm = 199 (* ledger: S6 *)
let op_arsh64_reg = 207 (* ledger: S6 *)
let op_hor64_imm = 247 (* ledger: S6 *)
let op_lmul64_imm = 150 (* ledger: S6 *)
let op_lmul64_reg = 158 (* ledger: S6 *)
let op_uhmul64_imm = 54 (* ledger: S6 *)
let op_uhmul64_reg = 62 (* ledger: S6 *)
let op_udiv64_imm = 86 (* ledger: S6 *)
let op_udiv64_reg = 94 (* ledger: S6 *)
let op_urem64_imm = 118 (* ledger: S6 *)
let op_urem64_reg = 126 (* ledger: S6 *)
let op_shmul64_imm = 182 (* ledger: S6 *)
let op_shmul64_reg = 190 (* ledger: S6 *)
let op_sdiv64_imm = 214 (* ledger: S6 *)
let op_sdiv64_reg = 222 (* ledger: S6 *)
let op_srem64_imm = 246 (* ledger: S6 *)
let op_srem64_reg = 254 (* ledger: S6 *)
let op_ja = 5 (* ledger: S6 *)
let op_jeq_imm = 21 (* ledger: S6 *)
let op_jeq_reg = 29 (* ledger: S6 *)
let op_jgt_imm = 37 (* ledger: S6 *)
let op_jgt_reg = 45 (* ledger: S6 *)
let op_jge_imm = 53 (* ledger: S6 *)
let op_jge_reg = 61 (* ledger: S6 *)
let op_jlt_imm = 165 (* ledger: S6 *)
let op_jlt_reg = 173 (* ledger: S6 *)
let op_jle_imm = 181 (* ledger: S6 *)
let op_jle_reg = 189 (* ledger: S6 *)
let op_jset_imm = 69 (* ledger: S6 *)
let op_jset_reg = 77 (* ledger: S6 *)
let op_jne_imm = 85 (* ledger: S6 *)
let op_jne_reg = 93 (* ledger: S6 *)
let op_jsgt_imm = 101 (* ledger: S6 *)
let op_jsgt_reg = 109 (* ledger: S6 *)
let op_jsge_imm = 117 (* ledger: S6 *)
let op_jsge_reg = 125 (* ledger: S6 *)
let op_jslt_imm = 197 (* ledger: S6 *)
let op_jslt_reg = 205 (* ledger: S6 *)
let op_jsle_imm = 213 (* ledger: S6 *)
let op_jsle_reg = 221 (* ledger: S6 *)
let op_call_imm = 133 (* ledger: S6 *)
let op_call_reg = 141 (* ledger: S6 *)
let op_return = 157 (* ledger: S6 *)
let op_syscall = 149 (* ledger: S6 *)
let elf_magic = "\127ELF" (* ledger: S4 *)

let opcode_values = [
  "LD_1B_REG", op_ld_1b_reg;
  "LD_2B_REG", op_ld_2b_reg;
  "LD_4B_REG", op_ld_4b_reg;
  "LD_8B_REG", op_ld_8b_reg;
  "ST_1B_IMM", op_st_1b_imm;
  "ST_2B_IMM", op_st_2b_imm;
  "ST_4B_IMM", op_st_4b_imm;
  "ST_8B_IMM", op_st_8b_imm;
  "ST_1B_REG", op_st_1b_reg;
  "ST_2B_REG", op_st_2b_reg;
  "ST_4B_REG", op_st_4b_reg;
  "ST_8B_REG", op_st_8b_reg;
  "ADD32_IMM", op_add32_imm;
  "ADD32_REG", op_add32_reg;
  "SUB32_IMM", op_sub32_imm;
  "SUB32_REG", op_sub32_reg;
  "OR32_IMM", op_or32_imm;
  "OR32_REG", op_or32_reg;
  "AND32_IMM", op_and32_imm;
  "AND32_REG", op_and32_reg;
  "LSH32_IMM", op_lsh32_imm;
  "LSH32_REG", op_lsh32_reg;
  "RSH32_IMM", op_rsh32_imm;
  "RSH32_REG", op_rsh32_reg;
  "XOR32_IMM", op_xor32_imm;
  "XOR32_REG", op_xor32_reg;
  "MOV32_IMM", op_mov32_imm;
  "MOV32_REG", op_mov32_reg;
  "ARSH32_IMM", op_arsh32_imm;
  "ARSH32_REG", op_arsh32_reg;
  "LMUL32_IMM", op_lmul32_imm;
  "LMUL32_REG", op_lmul32_reg;
  "UDIV32_IMM", op_udiv32_imm;
  "UDIV32_REG", op_udiv32_reg;
  "UREM32_IMM", op_urem32_imm;
  "UREM32_REG", op_urem32_reg;
  "SDIV32_IMM", op_sdiv32_imm;
  "SDIV32_REG", op_sdiv32_reg;
  "SREM32_IMM", op_srem32_imm;
  "SREM32_REG", op_srem32_reg;
  "ADD64_IMM", op_add64_imm;
  "ADD64_REG", op_add64_reg;
  "SUB64_IMM", op_sub64_imm;
  "SUB64_REG", op_sub64_reg;
  "OR64_IMM", op_or64_imm;
  "OR64_REG", op_or64_reg;
  "AND64_IMM", op_and64_imm;
  "AND64_REG", op_and64_reg;
  "LSH64_IMM", op_lsh64_imm;
  "LSH64_REG", op_lsh64_reg;
  "RSH64_IMM", op_rsh64_imm;
  "RSH64_REG", op_rsh64_reg;
  "XOR64_IMM", op_xor64_imm;
  "XOR64_REG", op_xor64_reg;
  "MOV64_IMM", op_mov64_imm;
  "MOV64_REG", op_mov64_reg;
  "ARSH64_IMM", op_arsh64_imm;
  "ARSH64_REG", op_arsh64_reg;
  "HOR64_IMM", op_hor64_imm;
  "LMUL64_IMM", op_lmul64_imm;
  "LMUL64_REG", op_lmul64_reg;
  "UHMUL64_IMM", op_uhmul64_imm;
  "UHMUL64_REG", op_uhmul64_reg;
  "UDIV64_IMM", op_udiv64_imm;
  "UDIV64_REG", op_udiv64_reg;
  "UREM64_IMM", op_urem64_imm;
  "UREM64_REG", op_urem64_reg;
  "SHMUL64_IMM", op_shmul64_imm;
  "SHMUL64_REG", op_shmul64_reg;
  "SDIV64_IMM", op_sdiv64_imm;
  "SDIV64_REG", op_sdiv64_reg;
  "SREM64_IMM", op_srem64_imm;
  "SREM64_REG", op_srem64_reg;
  "JA", op_ja;
  "JEQ_IMM", op_jeq_imm;
  "JEQ_REG", op_jeq_reg;
  "JGT_IMM", op_jgt_imm;
  "JGT_REG", op_jgt_reg;
  "JGE_IMM", op_jge_imm;
  "JGE_REG", op_jge_reg;
  "JLT_IMM", op_jlt_imm;
  "JLT_REG", op_jlt_reg;
  "JLE_IMM", op_jle_imm;
  "JLE_REG", op_jle_reg;
  "JSET_IMM", op_jset_imm;
  "JSET_REG", op_jset_reg;
  "JNE_IMM", op_jne_imm;
  "JNE_REG", op_jne_reg;
  "JSGT_IMM", op_jsgt_imm;
  "JSGT_REG", op_jsgt_reg;
  "JSGE_IMM", op_jsge_imm;
  "JSGE_REG", op_jsge_reg;
  "JSLT_IMM", op_jslt_imm;
  "JSLT_REG", op_jslt_reg;
  "JSLE_IMM", op_jsle_imm;
  "JSLE_REG", op_jsle_reg;
  "CALL_IMM", op_call_imm;
  "CALL_REG", op_call_reg;
  "RETURN", op_return;
  "SYSCALL", op_syscall;
]

let opcode (_ : t) name = List.assoc_opt (String.uppercase_ascii name) opcode_values

let frame_bytes (_ : t) = frame_bytes
let max_native_call_depth (_ : t) = max_native_call_depth
let heap_bytes (_ : t) = heap_bytes
let heap_max_bytes (_ : t) = heap_max_bytes
let cu_budget (_ : t) = cu_budget
let tx_byte_cap (_ : t) = tx_byte_cap
let image_cap_bytes (_ : t) = image_cap_bytes
let insn_size (_ : t) = insn_size
let e_flags_v3 (_ : t) = e_flags_v3
let e_type_dyn (_ : t) = e_type_dyn
let e_machine_sbpf (_ : t) = e_machine_sbpf
let ei_class_64 (_ : t) = ei_class_64
let ei_data_lsb (_ : t) = ei_data_lsb
let e_phoff (_ : t) = e_phoff
let e_phentsize (_ : t) = e_phentsize
let phdr_count (_ : t) = phdr_count
let syscall_base_cost (_ : t) = syscall_base_cost
let invoke_units (_ : t) = invoke_units
let cpi_bytes_per_unit (_ : t) = cpi_bytes_per_unit
let frame_alignment (_ : t) = frame_alignment
let word_bytes (_ : t) = word_bytes
let word_bits (_ : t) = word_bits
let register_nibble_bits (_ : t) = register_nibble_bits
let return_register (_ : t) = return_register
let frame_pointer_register (_ : t) = frame_pointer_register
let max_source_register (_ : t) = max_source_register
let max_destination_register (_ : t) = max_destination_register
let syscall_arg_first (_ : t) = syscall_arg_first
let syscall_arg_second (_ : t) = syscall_arg_second
let syscall_arg_third (_ : t) = syscall_arg_third
let syscall_arg_fourth (_ : t) = syscall_arg_fourth
let syscall_arg_fifth (_ : t) = syscall_arg_fifth
let stack_bytes (_ : t) = stack_bytes
let region_size (_ : t) = region_size
let mm_bytecode_start (_ : t) = mm_bytecode_start
let mm_rodata_start (_ : t) = mm_rodata_start
let mm_stack_start (_ : t) = mm_stack_start
let mm_heap_start (_ : t) = mm_heap_start
let mm_input_start (_ : t) = mm_input_start
let dynsym_sentinel_vaddr (_ : t) = dynsym_sentinel_vaddr
let e_ehsize (_ : t) = e_ehsize
let e_shentsize (_ : t) = e_shentsize
let elf_version (_ : t) = elf_version
let elf_osabi (_ : t) = elf_osabi
let elf_abi_version (_ : t) = elf_abi_version
let elf_half_bytes (_ : t) = elf_half_bytes
let elf_word_bytes (_ : t) = elf_word_bytes
let elf_xword_bytes (_ : t) = elf_xword_bytes
let elf_ident_size (_ : t) = elf_ident_size
let pt_null (_ : t) = pt_null
let pt_load (_ : t) = pt_load
let pt_gnu_stack (_ : t) = pt_gnu_stack
let pf_x (_ : t) = pf_x
let pf_w (_ : t) = pf_w
let pf_r (_ : t) = pf_r
let stt_func (_ : t) = stt_func
let symbol_size (_ : t) = symbol_size
let sht_null (_ : t) = sht_null
let sht_progbits (_ : t) = sht_progbits
let sht_strtab (_ : t) = sht_strtab
let sht_dynsym (_ : t) = sht_dynsym
let shf_alloc (_ : t) = shf_alloc
let shf_execinstr (_ : t) = shf_execinstr
let shn_undef (_ : t) = shn_undef
let off_ei_class (_ : t) = off_ei_class
let off_ei_data (_ : t) = off_ei_data
let off_ei_version (_ : t) = off_ei_version
let off_ei_osabi (_ : t) = off_ei_osabi
let off_ei_abiversion (_ : t) = off_ei_abiversion
let off_e_type (_ : t) = off_e_type
let off_e_machine (_ : t) = off_e_machine
let off_e_version (_ : t) = off_e_version
let off_e_entry (_ : t) = off_e_entry
let off_e_phoff (_ : t) = off_e_phoff
let off_e_shoff (_ : t) = off_e_shoff
let off_e_flags (_ : t) = off_e_flags
let off_e_ehsize (_ : t) = off_e_ehsize
let off_e_phentsize (_ : t) = off_e_phentsize
let off_e_phnum (_ : t) = off_e_phnum
let off_e_shentsize (_ : t) = off_e_shentsize
let off_e_shnum (_ : t) = off_e_shnum
let off_e_shstrndx (_ : t) = off_e_shstrndx
let off_p_type (_ : t) = off_p_type
let off_p_flags (_ : t) = off_p_flags
let off_p_offset (_ : t) = off_p_offset
let off_p_vaddr (_ : t) = off_p_vaddr
let off_p_paddr (_ : t) = off_p_paddr
let off_p_filesz (_ : t) = off_p_filesz
let off_p_memsz (_ : t) = off_p_memsz
let off_p_align (_ : t) = off_p_align
let off_sh_name (_ : t) = off_sh_name
let off_sh_type (_ : t) = off_sh_type
let off_sh_flags (_ : t) = off_sh_flags
let off_sh_addr (_ : t) = off_sh_addr
let off_sh_offset (_ : t) = off_sh_offset
let off_sh_size (_ : t) = off_sh_size
let off_sh_link (_ : t) = off_sh_link
let off_sh_info (_ : t) = off_sh_info
let off_sh_addralign (_ : t) = off_sh_addralign
let off_sh_entsize (_ : t) = off_sh_entsize
let off_st_name (_ : t) = off_st_name
let off_st_info (_ : t) = off_st_info
let off_st_other (_ : t) = off_st_other
let off_st_shndx (_ : t) = off_st_shndx
let off_st_value (_ : t) = off_st_value
let off_st_size (_ : t) = off_st_size
let op_ld_1b_reg (_ : t) = op_ld_1b_reg
let op_ld_2b_reg (_ : t) = op_ld_2b_reg
let op_ld_4b_reg (_ : t) = op_ld_4b_reg
let op_ld_8b_reg (_ : t) = op_ld_8b_reg
let op_st_1b_imm (_ : t) = op_st_1b_imm
let op_st_2b_imm (_ : t) = op_st_2b_imm
let op_st_4b_imm (_ : t) = op_st_4b_imm
let op_st_8b_imm (_ : t) = op_st_8b_imm
let op_st_1b_reg (_ : t) = op_st_1b_reg
let op_st_2b_reg (_ : t) = op_st_2b_reg
let op_st_4b_reg (_ : t) = op_st_4b_reg
let op_st_8b_reg (_ : t) = op_st_8b_reg
let op_add32_imm (_ : t) = op_add32_imm
let op_add32_reg (_ : t) = op_add32_reg
let op_sub32_imm (_ : t) = op_sub32_imm
let op_sub32_reg (_ : t) = op_sub32_reg
let op_or32_imm (_ : t) = op_or32_imm
let op_or32_reg (_ : t) = op_or32_reg
let op_and32_imm (_ : t) = op_and32_imm
let op_and32_reg (_ : t) = op_and32_reg
let op_lsh32_imm (_ : t) = op_lsh32_imm
let op_lsh32_reg (_ : t) = op_lsh32_reg
let op_rsh32_imm (_ : t) = op_rsh32_imm
let op_rsh32_reg (_ : t) = op_rsh32_reg
let op_xor32_imm (_ : t) = op_xor32_imm
let op_xor32_reg (_ : t) = op_xor32_reg
let op_mov32_imm (_ : t) = op_mov32_imm
let op_mov32_reg (_ : t) = op_mov32_reg
let op_arsh32_imm (_ : t) = op_arsh32_imm
let op_arsh32_reg (_ : t) = op_arsh32_reg
let op_lmul32_imm (_ : t) = op_lmul32_imm
let op_lmul32_reg (_ : t) = op_lmul32_reg
let op_udiv32_imm (_ : t) = op_udiv32_imm
let op_udiv32_reg (_ : t) = op_udiv32_reg
let op_urem32_imm (_ : t) = op_urem32_imm
let op_urem32_reg (_ : t) = op_urem32_reg
let op_sdiv32_imm (_ : t) = op_sdiv32_imm
let op_sdiv32_reg (_ : t) = op_sdiv32_reg
let op_srem32_imm (_ : t) = op_srem32_imm
let op_srem32_reg (_ : t) = op_srem32_reg
let op_add64_imm (_ : t) = op_add64_imm
let op_add64_reg (_ : t) = op_add64_reg
let op_sub64_imm (_ : t) = op_sub64_imm
let op_sub64_reg (_ : t) = op_sub64_reg
let op_or64_imm (_ : t) = op_or64_imm
let op_or64_reg (_ : t) = op_or64_reg
let op_and64_imm (_ : t) = op_and64_imm
let op_and64_reg (_ : t) = op_and64_reg
let op_lsh64_imm (_ : t) = op_lsh64_imm
let op_lsh64_reg (_ : t) = op_lsh64_reg
let op_rsh64_imm (_ : t) = op_rsh64_imm
let op_rsh64_reg (_ : t) = op_rsh64_reg
let op_xor64_imm (_ : t) = op_xor64_imm
let op_xor64_reg (_ : t) = op_xor64_reg
let op_mov64_imm (_ : t) = op_mov64_imm
let op_mov64_reg (_ : t) = op_mov64_reg
let op_arsh64_imm (_ : t) = op_arsh64_imm
let op_arsh64_reg (_ : t) = op_arsh64_reg
let op_hor64_imm (_ : t) = op_hor64_imm
let op_lmul64_imm (_ : t) = op_lmul64_imm
let op_lmul64_reg (_ : t) = op_lmul64_reg
let op_uhmul64_imm (_ : t) = op_uhmul64_imm
let op_uhmul64_reg (_ : t) = op_uhmul64_reg
let op_udiv64_imm (_ : t) = op_udiv64_imm
let op_udiv64_reg (_ : t) = op_udiv64_reg
let op_urem64_imm (_ : t) = op_urem64_imm
let op_urem64_reg (_ : t) = op_urem64_reg
let op_shmul64_imm (_ : t) = op_shmul64_imm
let op_shmul64_reg (_ : t) = op_shmul64_reg
let op_sdiv64_imm (_ : t) = op_sdiv64_imm
let op_sdiv64_reg (_ : t) = op_sdiv64_reg
let op_srem64_imm (_ : t) = op_srem64_imm
let op_srem64_reg (_ : t) = op_srem64_reg
let op_ja (_ : t) = op_ja
let op_jeq_imm (_ : t) = op_jeq_imm
let op_jeq_reg (_ : t) = op_jeq_reg
let op_jgt_imm (_ : t) = op_jgt_imm
let op_jgt_reg (_ : t) = op_jgt_reg
let op_jge_imm (_ : t) = op_jge_imm
let op_jge_reg (_ : t) = op_jge_reg
let op_jlt_imm (_ : t) = op_jlt_imm
let op_jlt_reg (_ : t) = op_jlt_reg
let op_jle_imm (_ : t) = op_jle_imm
let op_jle_reg (_ : t) = op_jle_reg
let op_jset_imm (_ : t) = op_jset_imm
let op_jset_reg (_ : t) = op_jset_reg
let op_jne_imm (_ : t) = op_jne_imm
let op_jne_reg (_ : t) = op_jne_reg
let op_jsgt_imm (_ : t) = op_jsgt_imm
let op_jsgt_reg (_ : t) = op_jsgt_reg
let op_jsge_imm (_ : t) = op_jsge_imm
let op_jsge_reg (_ : t) = op_jsge_reg
let op_jslt_imm (_ : t) = op_jslt_imm
let op_jslt_reg (_ : t) = op_jslt_reg
let op_jsle_imm (_ : t) = op_jsle_imm
let op_jsle_reg (_ : t) = op_jsle_reg
let op_call_imm (_ : t) = op_call_imm
let op_call_reg (_ : t) = op_call_reg
let op_return (_ : t) = op_return
let op_syscall (_ : t) = op_syscall
let elf_magic (_ : t) = elf_magic

(* No syscall_argument_registers list: an ordered argument-register vector is
   the shape of the S18 convention, and entry fact three keeps it out of
   Stage C. *)
let op_ldx64 = op_ld_8b_reg
let op_stx64 = op_st_8b_reg

(* Standard MurmurHash mixing constants, used by the symbol hash of row S7. *)
module Murmur = struct
  let zero = 0 (* ledger: S7 *)
  let byte_bits = 8 (* ledger: S7 *)
  let word_bits = 32 (* ledger: S7 *)
  let block_bytes = 4 (* ledger: S7 *)
  let last_byte_index = 3 (* ledger: S7 *)
  let key_rotation = 15 (* ledger: S7 *)
  let hash_rotation = 13 (* ledger: S7 *)
  let final_shift = 16 (* ledger: S7 *)
  let key_multiplier_first = 0xcc9e2d51l (* ledger: S7 *)
  let key_multiplier_second = 0x1b873593l (* ledger: S7 *)
  let hash_multiplier = 5l (* ledger: S7 *)
  let hash_increment = 0xe6546b64l (* ledger: S7 *)
  let final_multiplier_first = 0x85ebca6bl (* ledger: S7 *)
  let final_multiplier_second = 0xc2b2ae35l (* ledger: S7 *)
end
