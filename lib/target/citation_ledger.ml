module Row_map = Map.Make (String)

type status = Verified | Refuted | Unverified
type t = { statuses : status Row_map.t; order : string list }

type parse_error =
  | No_table
  | Malformed_table of { line : int; detail : string }
  | Duplicate_row of { line : int; id : string }
  | Invalid_status of { line : int; id : string; status : string }

type phase = Outside | Separator | Body

let malformed line detail = Error (Malformed_table { line; detail })

(* Escaped pipes stay in their cell. Traversal uses a sequence, without an
   unchecked index or a partial list operation. *)
let cells text =
  let add current cells = String.trim (String.of_seq (List.to_seq (List.rev current))) :: cells in
  let rec walk escaped current result chars =
    match chars () with
    | Seq.Nil ->
        let current = if escaped then '\\' :: current else current in
        List.rev (add current result)
    | Seq.Cons (ch, rest) ->
        match () with
        | () when escaped -> walk false (ch :: current) result rest
        | () when Char.equal ch '\\' -> walk true current result rest
        | () when Char.equal ch '|' -> walk false [] (add current result) rest
        | () -> walk false (ch :: current) result rest
  in
  match walk false [] [] (String.to_seq text) with
  | "" :: id :: fact :: value :: obligation :: status :: [ "" ] ->
      Some (id, fact, value, obligation, status)
  | _ -> None

let valid_id id =
  let uppercase = function 'A' .. 'Z' -> true | _ -> false in
  let tail = function 'A' .. 'Z' | '0' .. '9' | '-' -> true | _ -> false in
  match String.to_seq id () with
  | Seq.Nil -> false
  | Seq.Cons (first, rest) -> uppercase first && Seq.for_all tail rest

let separator_cell cell =
  let hyphens = String.fold_left (fun total ch -> if Char.equal ch '-' then total + 1 else total) 0 cell in
  hyphens >= 3 && String.for_all (function '-' | ':' -> true | _ -> false) cell

let parse_status line id status =
  match String.split_on_char ' ' status |> List.filter (fun word -> not (String.equal word "")) with
  | "VERIFIED" :: _ :: _ -> Ok Verified
  | "VERIFIED-REFUTED" :: _ :: _ -> Ok Refuted
  | "UNVERIFIED" :: _ -> Ok Unverified
  | _ -> Error (Invalid_status { line; id; status })

let parse text =
  let rec loop line phase seen_header statuses order = function
    | [] ->
        (match phase with
         | Separator -> malformed line "missing header separator"
         | Outside | Body ->
             if not seen_header || Row_map.is_empty statuses then Error No_table
             else Ok { statuses; order = List.rev order })
    | raw :: rest ->
        let text = String.trim raw in
        let is_table = String.starts_with ~prefix:"|" text in
        if not is_table then
          (match phase with
           | Separator -> malformed line "expected header separator"
           | Outside | Body -> loop (line + 1) Outside seen_header statuses order rest)
        else
          Option.fold
            ~none:(malformed line "expected five cells with leading and trailing pipes")
            ~some:(fun (id, fact, value, obligation, status) ->
              match () with
              | () when String.equal id "id" && phase = Separator ->
                  malformed line "missing header separator"
              | () when String.equal id "id" ->
                  if String.equal status "status"
                     && List.for_all (fun cell -> not (String.equal cell "")) [ fact; value; obligation ] then
                    loop (line + 1) Separator true statuses order rest
                  else malformed line "invalid ledger header"
              | () ->
                  match phase with
                  | Outside -> malformed line "row outside a ledger table"
                  | Separator ->
                      if List.for_all separator_cell [ id; fact; value; obligation; status ] then
                        loop (line + 1) Body seen_header statuses order rest
                      else malformed line "invalid header separator"
                  | Body ->
                      match () with
                      | () when not (valid_id id) -> malformed line "invalid row id"
                      | () when List.exists (String.equal "") [ fact; value; obligation ] ->
                          malformed line "empty fact, value, or citation obligation"
                      | () when Row_map.mem id statuses -> Error (Duplicate_row { line; id })
                      | () ->
                          Result.bind (parse_status line id status) (fun status ->
                            loop (line + 1) Body seen_header (Row_map.add id status statuses) (id :: order) rest))
            (cells text)
  in
  loop 1 Outside false Row_map.empty [] (String.split_on_char '\n' text)

let verified ledger id =
  Option.fold ~none:false
    ~some:(function Verified -> true | Refuted | Unverified -> false)
    (Row_map.find_opt id ledger.statuses)

let rows ledger = ledger.order

let pp_error = function
  | No_table -> "citation ledger contains no rows"
  | Malformed_table { line; detail } -> Printf.sprintf "citation ledger line %d: %s" line detail
  | Duplicate_row { line; id } -> Printf.sprintf "citation ledger line %d: duplicate row %s" line id
  | Invalid_status { line; id; status } ->
      Printf.sprintf "citation ledger line %d: invalid status for %s: %s" line id status
