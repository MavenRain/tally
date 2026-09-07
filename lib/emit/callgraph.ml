open Tally_cterm.Cterm
let ( let* ) = Result.bind
type t = { edges : (code_tag * code_tag list) list; ordered : code_tag list }
let successors graph tag = Option.value (List.assoc_opt tag graph.edges) ~default:[]
let order graph = graph.ordered
let rec calls body =
  let own = List.filter_map (fun (_, rhs) -> match rhs with
    | RCallKnown (tag, _) -> Some tag
    | RAtom _ | RMkClo _ | RMkKont _ | RMkCon _ | RProj _ | RPrim _ | RSyscall _ | RApply _ -> None) body.binds in
  match body.tail with
  | TSwitch (_, branches, default) -> own @ List.concat_map (fun (_, b) -> calls b) branches @ calls default
  | TRet _ | TApply _ | TResume _ | TTrap _ -> own
let program p =
  let edges = Array.to_list p.codes |> List.map (fun code -> code.code_id, List.sort_uniq compare (calls code.body)) in
  let graph = { edges; ordered = [] } in
  let name tag = code_of_tag p tag |> Option.map (fun code -> code.name) |> Option.value ~default:"<unknown>" in
  let rec visit active done_ tag =
    if List.mem tag active then Error (Emit_error.Call_graph_cycle (List.rev_map name (tag :: active)))
    else if List.mem tag done_ then Ok done_
    else
      let* _ = code_of_tag p tag |> Option.to_result ~none:(Emit_error.Unsupported_term "native call names an unknown code tag") in
      let* done_ = List.fold_left (fun result next -> let* done_ = result in visit (tag :: active) done_ next)
        (Ok done_) (successors graph tag) in
      Ok (done_ @ [tag]) in
  let* ordered = List.fold_left (fun result (tag, _) -> let* done_ = result in visit [] done_ tag) (Ok []) edges in
  Ok { graph with ordered }
