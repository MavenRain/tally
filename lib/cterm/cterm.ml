open Tot_kernel
type code_tag = Code_tag of int
type kont_tag = Kont_tag of int
type slot = Slot of int
type field = Field of int * int
type ctor = Ctor of string
module Syscall = struct type t = Sol_log end
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
  kont_frame_slots : int;
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
let slot i = if i < 0 then None else Some (Slot i)
let field ~arity i = if i < 0 || i >= arity then None else Some (Field (i, arity))
let ctor name = Ctor name
let slot_index (Slot i) = i
let field_index (Field (i, _)) = i
let field_arity (Field (_, arity)) = arity
let code_index (Code_tag i) = i
let kont_index (Kont_tag i) = i
let ctor_name (Ctor name) = name
let append_code codes ~name ~kind ~parameters ~capture_slots ~body =
  let code_id = Code_tag (List.length codes) in
  let code = { code_id; name; kind; arity = List.length parameters;
    captures = List.length capture_slots; parameters; capture_slots;
    frame_slots = 0; body } in
  code_id, codes @ [code]
let append_kont konts ~capture_slots ~result ~body =
  let kont_id = Kont_tag (List.length konts) in
  let kont = { kont_id; kont_captures = List.length capture_slots;
    kont_capture_slots = capture_slots; kont_result = result;
    kont_frame_slots = 0; kont_body = body } in
  kont_id, konts @ [kont]
let code_of_tag p (Code_tag i) =
  if i < 0 then None else
  Array.to_seq p.codes |> Seq.drop i |> Seq.uncons |> Option.map fst
let kont_of_tag p (Kont_tag i) =
  if i < 0 then None else
  Array.to_seq p.konts |> Seq.drop i |> Seq.uncons |> Option.map fst
