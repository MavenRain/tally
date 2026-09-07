type t = { height : int option; bounds : (string * int) list; explicit : bool }
let empty = { height = None; bounds = []; explicit = false }
let entry_height d = Option.value d.height ~default:1
let depth_bound d target = List.assoc_opt target d.bounds
let is_explicit d = d.explicit
let ( let* ) = Result.bind

let error line detail =
  Error (Cerror.Cerr_declaration
    (Cerror.diagnostic ~span:("line " ^ string_of_int line) "<declarations>" detail))

let natural line text =
  if String.length text = 0 || not (String.for_all (fun c -> c >= '0' && c <= '9') text)
  then error line ("expected a decimal natural number: " ^ text)
  else int_of_string_opt text |> Option.fold
    ~none:(error line ("natural number exceeds host representation: " ^ text))
    ~some:(fun n -> if n >= 0 then Ok n else error line "negative natural number")

let identifier text =
  let initial c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_' in
  match String.to_seq text |> List.of_seq with
  | [] -> false
  | c :: rest -> initial c && List.for_all (fun c -> initial c || (c >= '0' && c <= '9') || c = '\'') rest

let words text =
  String.map (function '\t' | '\r' -> ' ' | c -> c) text
  |> String.split_on_char ' ' |> List.filter (fun word -> word <> "")

let add line d = function
  | ["entry-height"; text] ->
      let* height = natural line text in
      if Option.is_some d.height then error line "duplicate entry-height"
      else Ok { d with height = Some height; explicit = true }
  | ["depth-bound"; target; text] ->
      if not (identifier target) then error line ("invalid global name: " ^ target)
      else if List.mem_assoc target d.bounds then error line ("duplicate depth-bound: " ^ target)
      else let* bound = natural line text in
        Ok { d with bounds = d.bounds @ [target, bound]; explicit = true }
  | [] -> Ok d
  | tokens -> error line ("invalid declaration: " ^ String.concat " " tokens)

(** Only line comments exist in the source lexer. Keep quoted newlines and
    escaped quotes intact, so declaration-looking string data is never removed. *)
type quoted = Outside | Inside | Escaped
let rec scan quoted = function
  | [] -> quoted
  | '-' :: '-' :: _ when quoted = Outside -> Outside
  | '"' :: rest when quoted = Outside -> scan Inside rest
  | '"' :: rest when quoted = Inside -> scan Outside rest
  | '\\' :: rest when quoted = Inside -> scan Escaped rest
  | _ :: rest when quoted = Escaped -> scan Inside rest
  | _ :: rest -> scan quoted rest

let rec comment_prefix rev = function
  | '-' :: '-' :: _ | [] -> String.of_seq (List.to_seq (List.rev rev))
  | c :: rest -> comment_prefix (c :: rev) rest

let parse text =
  let rec lines number d = function
    | [] -> Ok d
    | line :: rest ->
        let* d = add number d (words (comment_prefix [] (List.of_seq (String.to_seq line)))) in
        lines (number + 1) d rest
  in lines 1 empty (String.split_on_char '\n' text)

let source text =
  let rec lines number quoted d rev = function
    | [] -> Ok (String.concat "\n" (List.rev rev), d)
    | line :: rest ->
        let tokens = words (comment_prefix [] (List.of_seq (String.to_seq line))) in
        (match quoted, tokens with
         | Outside, (("entry-height" | "depth-bound") :: _) ->
             let* d = add number d tokens in
             lines (number + 1) Outside d (String.make (String.length line) ' ' :: rev) rest
         | (Outside | Inside | Escaped), _ ->
             let quoted = scan quoted (List.of_seq (String.to_seq (line ^ "\n"))) in
             lines (number + 1) quoted d (line :: rev) rest)
  in lines 1 Outside empty [] (String.split_on_char '\n' text)
