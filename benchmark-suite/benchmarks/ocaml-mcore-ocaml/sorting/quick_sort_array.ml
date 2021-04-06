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

let rand_array n =
  Array.make n 0
  |> Array.mapi (fun i _ -> rand (i + 1))

let partition a lo hi =
  let swap i j =
    let temp = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- temp;
  in
  let pivot = a.(lo) in
  let i = ref hi in
  for j = hi downto lo do
    if a.(j) > pivot then
      (swap !i j;
       i := !i - 1)
    else ();
  done;
  swap !i lo;
  !i

let quicksort (a : int Array.t) =
  let rec quicksort_rec a lo hi =
    if lo < hi then
       let p = partition a lo hi in
       quicksort_rec a lo (p - 1);
       quicksort_rec a (p + 1) hi;
    else ()
  in quicksort_rec a 0 (Array.length a - 1); a

let _ =
  read_line ()
  |> int_of_string
  |> rand_array
  |> quicksort
  (* |> Array.to_list
   * |> List.map string_of_int
   * |> String.concat "\n"
   * |> print_endline *)
