type bstree =
  | Node of bstree * int * bstree
  (* NOTE(Linnea, 2021-03-29): Empty variants not supported by ocaml2mcore yet *)
  | Leaf of unit

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

let rec insert x = function
  | Leaf _ -> Node (Leaf (), x, Leaf ())
  | Node (l, k, r) as t ->
    if x < k then
      Node (insert x l, k, r)
    else if x > k then
      Node (l, k, insert x r)
    else t

let rec insertn seed t = function
  | 0 -> t
  | n ->
    let r = rand seed in
    insertn r (insert r t) (n-1)

let rec lookup x = function
  | Leaf _ -> false
  | Node (l, k, r) ->
    if x < k then lookup x l
    else if x > k then lookup x r
    else true

let rec lookupn seed t = function
  | 0 -> ()
  | n ->
    let r = rand seed in
    let _ = lookup r t in
    lookupn r t (n-1)

let _ =
  (* NOTE(Linnea, 2021-03-29): We need to create a dummy instance of each
     variant in order to discover its type in ocaml2mcore. *)
  let _ = Node (Leaf (), 2, Leaf ()) in

  let n = int_of_string (read_line ()) in

  (* Insert n random elements *)
  let t = insertn 1 (Leaf ()) n in

  (* Lookup the same sequence of n elements *)
  let _ = lookupn 1 t n in

  (* Lookup a sequence of fresh random elements *)
  let _ = lookupn 5 t n in

  ()
