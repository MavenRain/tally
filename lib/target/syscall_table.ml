module Mix = Target_params.Murmur

type t = Table of Target_params.t
type lookup_error = Unknown_syscall of string

let of_params params = Table params
let names (Table _) = [ "sol_log_"; "sol_get_stack_height"; "sol_invoke_signed_rust" ]

let rotate_left value shift =
  Int32.logor (Int32.shift_left value shift)
    (Int32.shift_right_logical value (Mix.word_bits - shift))

let mix_key value =
  Int32.mul
    (rotate_left (Int32.mul value Mix.key_multiplier_first) Mix.key_rotation)
    Mix.key_multiplier_second

let mix_hash hash word =
  Int32.add
    (Int32.mul (rotate_left (Int32.logxor hash (mix_key word)) Mix.hash_rotation)
       Mix.hash_multiplier)
    Mix.hash_increment

let finish hash length =
  let hash = Int32.logxor hash length in
  let hash = Int32.logxor hash (Int32.shift_right_logical hash Mix.final_shift) in
  let hash = Int32.mul hash Mix.final_multiplier_first in
  let hash = Int32.logxor hash (Int32.shift_right_logical hash Mix.hash_rotation) in
  let hash = Int32.mul hash Mix.final_multiplier_second in
  Int32.logxor hash (Int32.shift_right_logical hash Mix.final_shift)

let murmur3_key name =
  let consume (hash, word, byte_index, length) ch =
    let byte = Int32.of_int (Char.code ch) in
    let word = Int32.logor word (Int32.shift_left byte (byte_index * Mix.byte_bits)) in
    let length = Int32.succ length in
    if byte_index = Mix.last_byte_index then
      (mix_hash hash word, Int32.zero, Mix.zero, length)
    else (hash, word, succ byte_index, length)
  in
  let hash, word, tail_length, length =
    String.fold_left consume (Int32.zero, Int32.zero, Mix.zero, Int32.zero) name
  in
  let hash = if tail_length = Mix.zero then hash else Int32.logxor hash (mix_key word) in
  finish hash length

let key table name =
  if List.exists (String.equal name) (names table) then Ok (murmur3_key name)
  else Error (Unknown_syscall name)
