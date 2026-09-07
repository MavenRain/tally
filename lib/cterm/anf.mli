open Tot_kernel
type atom = Local of Cterm.slot | Global of string | Lit of Cterm.lit | Erased
type rhs = Atom of atom | Apply of atom * atom list | Lambda of Cterm.slot * block
and block = Return of atom | Let of Cterm.slot * rhs * block
  | Switch of atom * (string * Cterm.slot list * block) list
type definition = { name : string; parameters : Cterm.slot list; body : block }
type symbol = Defined of int | Constructor of int | Primitive of Prim.t | Erased_global
type t = { root : string; definitions : definition list; symbols : (string * symbol) list }
val program : Global.t -> root:string -> (t, Cerror.t) result
