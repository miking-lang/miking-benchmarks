(* Linear congruential generator: https://en.wikipedia.org/wiki/Linear_congruential_generator *)
let lcg m a c x =
  (a * x + c) mod m

(* Generates a random number between 0 and 1073741789 *)
(* Parameters to LCG taken from
   https://www.ams.org/journals/mcom/1999-68-225/S0025-5718-99-00996-5/S0025-5718-99-00996-5.PDP
*)
let rand seed =
  let r = lcg 1073741789 771645345 0 seed in
  r

let rand_list n =
  Rope.create_array n (fun i -> rand (i + 1))

let head r =
  Rope.get_array r 0

let tail r =
  Rope.sub_array r 1 (Rope.length_array r - 1)

let rec filter p r =
  match Rope.length_array r with
  | 0 ->
    Rope.empty_array
  | _ ->
    if p (head r) then
      Rope.cons_array (head r) (filter p (tail r))
    else filter p (tail r)

let partition p r =
  let l, r = (filter p r, filter (fun x -> not (p x)) r) in
  l, r

let rec quicksort r =
  match Rope.length_array r with
  | 0 -> r
  | _ ->
    let h = head r in
    let t = tail r in
    let l, r = partition (fun x -> x < h) t in
    Rope.concat_array (quicksort l) (Rope.cons_array h (quicksort r))

let _ =
  read_line ()
  |> int_of_string
  |> rand_list
  |> quicksort
  (* |> Rope.Convert.to_list_array
   * |> List.map string_of_int
   * |> String.concat "\n"
   * |> print_endline *)

