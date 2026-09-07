open Tot_kernel
type code_tag = private Code_tag of int
type kont_tag = private Kont_tag of int
type slot = private Slot of int
type field = private Field of int * int
type ctor = private Ctor of string
module Syscall : sig type t = Sol_log end
type lit = LStr of string | LInt of int | LWord of Word.width * Word.sign * Int64.t
type atom = ALocal of slot | AGlobal of ctor | ALit of lit | AErased
type rhs =
  | RAtom of atom
  | RMkClo of code_tag * atom list
  | RMkKont of kont_tag * atom list
  | RMkCon of ctor * atom list
  | RProj of atom * field
  | RPrim of Prim.t * atom list
  | RSyscall of Syscall.t * atom list
  | RCallKnown of code_tag * atom list
  | RApply of atom * atom
and tail =
  | TRet of atom
  | TApply of atom * atom
  | TResume of atom * atom
  | TSwitch of atom * (ctor * block) list * block
  | TTrap of trap
and block = { binds : (slot * rhs) list; tail : tail }
and trap = Trap_impossible_ctor
type code_kind = Global | Closure | Dispatch
type code = {
  code_id : code_tag;
  name : string;
  kind : code_kind;
  arity : int;
  captures : int;
  parameters : slot list;
  capture_slots : slot list;
  frame_slots : int;
  body : block;
}
type kont = {
  kont_id : kont_tag;
  kont_captures : int;
  kont_capture_slots : slot list;
  kont_result : slot;
  kont_body : block;
}
type program = {
  codes : code array;
  konts : kont array;
  entry : code_tag;
  arena_words : int;
  rodata : string;
  strings : (string * int * int) list;
}
val slot : int -> slot option
val field : arity:int -> int -> field option
val ctor : string -> ctor
val slot_index : slot -> int
val field_index : field -> int
val field_arity : field -> int
val code_index : code_tag -> int
val kont_index : kont_tag -> int
val ctor_name : ctor -> string
val append_code : code list -> name:string -> kind:code_kind -> parameters:slot list -> capture_slots:slot list -> body:block -> code_tag * code list
val append_kont : kont list -> capture_slots:slot list -> result:slot -> body:block -> kont_tag * kont list
val code_of_tag : program -> code_tag -> code option
val kont_of_tag : program -> kont_tag -> kont option
