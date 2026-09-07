open Tot_kernel
type rhs = Atom of Cterm.atom | MkClo of string * Cterm.atom list
  | MkCon of Cterm.ctor * Cterm.atom list | Proj of Cterm.atom * Cterm.field
  | Prim of Prim.t * Cterm.atom list | CallKnown of string * Cterm.atom list
  | Apply of Cterm.atom * Cterm.atom
type block = { binds : (Cterm.slot * rhs) list; tail : tail }
and tail = Return of Cterm.atom | Switch of Cterm.atom * (Cterm.ctor * block) list
type code = { name : string; kind : Cterm.code_kind; parameters : Cterm.slot list;
  capture_slots : Cterm.slot list; body : block }
type t = { root : string; codes : code list }
val program : Anf.t -> (t, Cerror.t) result
