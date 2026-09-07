(** Citation-checked parameters for leaf code on the pinned target. *)
type t
type build_error = Row_unverified of string | Unknown_target of string
val of_ledger : Citation_ledger.t -> string -> (t, build_error) result
val require_calling_convention : t -> (unit, build_error) result
val required_rows : string list
val opcode : t -> string -> int option

val frame_bytes : t -> int
val max_native_call_depth : t -> int
val heap_bytes : t -> int
val heap_max_bytes : t -> int
val cu_budget : t -> int
val tx_byte_cap : t -> int
val image_cap_bytes : t -> int
val insn_size : t -> int
val e_flags_v3 : t -> int
val e_type_dyn : t -> int
val e_machine_sbpf : t -> int
val ei_class_64 : t -> int
val ei_data_lsb : t -> int
val e_phoff : t -> int
val e_phentsize : t -> int
val phdr_count : t -> int
val syscall_base_cost : t -> int
val invoke_units : t -> int
val cpi_bytes_per_unit : t -> int
val frame_alignment : t -> int
val word_bytes : t -> int
val word_bits : t -> int
val register_nibble_bits : t -> int
val return_register : t -> int
val frame_pointer_register : t -> int
val max_source_register : t -> int
val max_destination_register : t -> int
val syscall_arg_first : t -> int
val syscall_arg_second : t -> int
val syscall_arg_third : t -> int
val syscall_arg_fourth : t -> int
val syscall_arg_fifth : t -> int
val stack_bytes : t -> int
val region_size : t -> int64
val mm_bytecode_start : t -> int64
val mm_rodata_start : t -> int64
val mm_stack_start : t -> int64
val mm_heap_start : t -> int64
val mm_input_start : t -> int64
val dynsym_sentinel_vaddr : t -> int64
val e_ehsize : t -> int
val e_shentsize : t -> int
val elf_version : t -> int
val elf_osabi : t -> int
val elf_abi_version : t -> int
val elf_half_bytes : t -> int
val elf_word_bytes : t -> int
val elf_xword_bytes : t -> int
val elf_ident_size : t -> int
val pt_null : t -> int
val pt_load : t -> int
val pt_gnu_stack : t -> int
val pf_x : t -> int
val pf_w : t -> int
val pf_r : t -> int
val stt_func : t -> int
val symbol_size : t -> int
val sht_null : t -> int
val sht_progbits : t -> int
val sht_strtab : t -> int
val sht_dynsym : t -> int
val shf_alloc : t -> int
val shf_execinstr : t -> int
val shn_undef : t -> int
val off_ei_class : t -> int
val off_ei_data : t -> int
val off_ei_version : t -> int
val off_ei_osabi : t -> int
val off_ei_abiversion : t -> int
val off_e_type : t -> int
val off_e_machine : t -> int
val off_e_version : t -> int
val off_e_entry : t -> int
val off_e_phoff : t -> int
val off_e_shoff : t -> int
val off_e_flags : t -> int
val off_e_ehsize : t -> int
val off_e_phentsize : t -> int
val off_e_phnum : t -> int
val off_e_shentsize : t -> int
val off_e_shnum : t -> int
val off_e_shstrndx : t -> int
val off_p_type : t -> int
val off_p_flags : t -> int
val off_p_offset : t -> int
val off_p_vaddr : t -> int
val off_p_paddr : t -> int
val off_p_filesz : t -> int
val off_p_memsz : t -> int
val off_p_align : t -> int
val off_sh_name : t -> int
val off_sh_type : t -> int
val off_sh_flags : t -> int
val off_sh_addr : t -> int
val off_sh_offset : t -> int
val off_sh_size : t -> int
val off_sh_link : t -> int
val off_sh_info : t -> int
val off_sh_addralign : t -> int
val off_sh_entsize : t -> int
val off_st_name : t -> int
val off_st_info : t -> int
val off_st_other : t -> int
val off_st_shndx : t -> int
val off_st_value : t -> int
val off_st_size : t -> int
val op_ld_1b_reg : t -> int
val op_ld_2b_reg : t -> int
val op_ld_4b_reg : t -> int
val op_ld_8b_reg : t -> int
val op_st_1b_imm : t -> int
val op_st_2b_imm : t -> int
val op_st_4b_imm : t -> int
val op_st_8b_imm : t -> int
val op_st_1b_reg : t -> int
val op_st_2b_reg : t -> int
val op_st_4b_reg : t -> int
val op_st_8b_reg : t -> int
val op_add32_imm : t -> int
val op_add32_reg : t -> int
val op_sub32_imm : t -> int
val op_sub32_reg : t -> int
val op_or32_imm : t -> int
val op_or32_reg : t -> int
val op_and32_imm : t -> int
val op_and32_reg : t -> int
val op_lsh32_imm : t -> int
val op_lsh32_reg : t -> int
val op_rsh32_imm : t -> int
val op_rsh32_reg : t -> int
val op_xor32_imm : t -> int
val op_xor32_reg : t -> int
val op_mov32_imm : t -> int
val op_mov32_reg : t -> int
val op_arsh32_imm : t -> int
val op_arsh32_reg : t -> int
val op_lmul32_imm : t -> int
val op_lmul32_reg : t -> int
val op_udiv32_imm : t -> int
val op_udiv32_reg : t -> int
val op_urem32_imm : t -> int
val op_urem32_reg : t -> int
val op_sdiv32_imm : t -> int
val op_sdiv32_reg : t -> int
val op_srem32_imm : t -> int
val op_srem32_reg : t -> int
val op_add64_imm : t -> int
val op_add64_reg : t -> int
val op_sub64_imm : t -> int
val op_sub64_reg : t -> int
val op_or64_imm : t -> int
val op_or64_reg : t -> int
val op_and64_imm : t -> int
val op_and64_reg : t -> int
val op_lsh64_imm : t -> int
val op_lsh64_reg : t -> int
val op_rsh64_imm : t -> int
val op_rsh64_reg : t -> int
val op_xor64_imm : t -> int
val op_xor64_reg : t -> int
val op_mov64_imm : t -> int
val op_mov64_reg : t -> int
val op_arsh64_imm : t -> int
val op_arsh64_reg : t -> int
val op_hor64_imm : t -> int
val op_lmul64_imm : t -> int
val op_lmul64_reg : t -> int
val op_uhmul64_imm : t -> int
val op_uhmul64_reg : t -> int
val op_udiv64_imm : t -> int
val op_udiv64_reg : t -> int
val op_urem64_imm : t -> int
val op_urem64_reg : t -> int
val op_shmul64_imm : t -> int
val op_shmul64_reg : t -> int
val op_sdiv64_imm : t -> int
val op_sdiv64_reg : t -> int
val op_srem64_imm : t -> int
val op_srem64_reg : t -> int
val op_ja : t -> int
val op_jeq_imm : t -> int
val op_jeq_reg : t -> int
val op_jgt_imm : t -> int
val op_jgt_reg : t -> int
val op_jge_imm : t -> int
val op_jge_reg : t -> int
val op_jlt_imm : t -> int
val op_jlt_reg : t -> int
val op_jle_imm : t -> int
val op_jle_reg : t -> int
val op_jset_imm : t -> int
val op_jset_reg : t -> int
val op_jne_imm : t -> int
val op_jne_reg : t -> int
val op_jsgt_imm : t -> int
val op_jsgt_reg : t -> int
val op_jsge_imm : t -> int
val op_jsge_reg : t -> int
val op_jslt_imm : t -> int
val op_jslt_reg : t -> int
val op_jsle_imm : t -> int
val op_jsle_reg : t -> int
val op_call_imm : t -> int
val op_call_reg : t -> int
val op_return : t -> int
val op_syscall : t -> int
val elf_magic : t -> string
val op_ldx64 : t -> int
val op_stx64 : t -> int

(** Algorithm constants only. These do not construct a target capability. *)
module Murmur : sig
  val zero : int
  val byte_bits : int
  val word_bits : int
  val block_bytes : int
  val last_byte_index : int
  val key_rotation : int
  val hash_rotation : int
  val final_shift : int
  val key_multiplier_first : int32
  val key_multiplier_second : int32
  val hash_multiplier : int32
  val hash_increment : int32
  val final_multiplier_first : int32
  val final_multiplier_second : int32
end
