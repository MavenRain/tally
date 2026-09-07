open Tally_cterm.Cterm
type location = Register of int | Spill of int
type t = { assignments : (slot * location) list; spills : int }
let location allocation slot = List.assoc_opt slot allocation.assignments
let spill_words allocation = allocation.spills
module Slots = Map.Make (struct type t = slot let compare = compare end)
type interval = { slot : slot; first : int; last : int }
let allocate inputs body =
  let intervals = ref Slots.empty in
  let position = ref 0 in
  let mention slot =
    let next = Slots.find_opt slot !intervals
      |> Option.fold ~none:{ slot; first = !position; last = !position }
           ~some:(fun interval -> { interval with last = max !position interval.last }) in
    intervals := Slots.add slot next !intervals in
  let atom = function ALocal slot -> mention slot | AGlobal _ | ALit _ | AErased -> () in
  let rhs = function
    | RAtom a | RProj (a, _) -> atom a
    | RMkClo (_, xs) | RMkKont (_, xs) | RMkCon (_, xs) | RPrim (_, xs)
    | RSyscall (_, xs) | RCallKnown (_, xs) -> List.iter atom xs
    | RApply (f, a) -> atom f; atom a in
  let rec block body =
    List.iter (fun (slot, expression) -> incr position; rhs expression; mention slot) body.binds;
    incr position;
    match body.tail with
    | TRet value -> atom value
    | TApply (f, a) | TResume (f, a) -> atom f; atom a
    | TTrap _ -> ()
    | TSwitch (value, branches, default) -> atom value; List.iter (fun (_, b) -> block b) branches; block default in
  List.iter mention inputs;
  block body;
  let intervals = Slots.bindings !intervals |> List.map snd
    |> List.sort (fun a b -> let by_start = Int.compare a.first b.first in
         if by_start = 0 then compare a.slot b.slot else by_start) in
  (* These registers are a leaf-local allocation choice. Native calls are
     rejected before this allocation is used for instruction selection. *)
  let registers = [6; 7; 8; 9] in
  let _, assignments, spills = List.fold_left (fun (active, assignments, spills) interval ->
    let active = List.filter (fun (_, last) -> last >= interval.first) active in
    List.find_opt (fun register -> not (List.mem_assoc register active)) registers
    |> Option.fold
         ~none:(active, (interval.slot, Spill spills) :: assignments, spills + 1)
         ~some:(fun register -> (register, interval.last) :: active,
           (interval.slot, Register register) :: assignments, spills))
    ([], [], 0) intervals in
  { assignments; spills }
let code code = allocate (code.parameters @ code.capture_slots) code.body
let continuation kont = allocate (kont.kont_result :: kont.kont_capture_slots) kont.kont_body
