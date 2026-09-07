type t = {
  bytecode : int64;
  rodata : int64;
  stack : int64;
  heap : int64;
  input : int64;
}

let of_params params = {
  bytecode = Target_params.mm_bytecode_start params;
  rodata = Target_params.mm_rodata_start params;
  stack = Target_params.mm_stack_start params;
  heap = Target_params.mm_heap_start params;
  input = Target_params.mm_input_start params;
}

let bytecode regions = regions.bytecode
let rodata regions = regions.rodata
let stack regions = regions.stack
let heap regions = regions.heap
let input regions = regions.input
