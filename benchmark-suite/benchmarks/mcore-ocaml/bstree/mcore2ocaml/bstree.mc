type Bstree
con Node : (Bstree, Int, Bstree) -> Bstree
con Leaf : () -> Bstree

let head = lam seq. get seq 0
let tail = lam seq. subsequence seq 1 (subi (length seq) 1)
let eqChar = lam c1. lam c2. eqc c1 c2

let string2int = lam s.
  recursive
  let string2int_rechelper = lam s.
    let len = length s in
    let last = subi len 1 in
    if eqi len 0
    then 0
    else
      let lsd = subi (char2int (get s last)) (char2int '0') in
      let rest = muli 10 (string2int_rechelper (subsequence s 0 last)) in
      addi rest lsd
  in
  match s with [] then 0 else
  if eqChar '-' (head s)
  then negi (string2int_rechelper (tail s))
  else string2int_rechelper s

-- Linear congruential generator: https://en.wikipedia.org/wiki/Linear_congruential_generator
let lcg = lam m. lam a. lam c. lam x.
  modi (addi (muli a x) c) m

-- Generates a random number between 0 and 1073741789
-- Parameters to LCG taken from
-- https://www.ams.org/journals/mom/1999-68-225/S0025-5718-99-00996-5/S0025-5718-99-00996-5.PDP
let rand = lam seed.
  let r = lcg 1073741789 771645345 0 seed in
  r

recursive let insert = lam x. lam tree.
  match tree with Leaf _ then
    Node (Leaf (), x, Leaf ())
  else match tree with Node (l, k, r) then
    if lti x k then
      Node (insert x l, k, r)
    else if gti x k then
      Node (l, k, insert x r)
    else tree
  else never
end

recursive let insertn = lam seed. lam tree. lam n.
  match n with 0 then
    tree
  else match n with _ then
    let r = rand seed in
    insertn r (insert r tree) (subi n 1)
  else never
end

recursive let lookup = lam x. lam tree.
  match tree with Leaf _ then
    false
  else match tree with Node (l, k, r) then
    if lti x k then
      lookup x l
    else if gti x k then
      lookup x r
    else true
  else never
end

recursive let lookupn = lam seed. lam tree. lam n.
  match n with 0 then
    ()
  else match n with n then
    let r = rand seed in
    lookup r tree;
    lookupn r tree (subi n 1)
  else never
end


let _v =
  let n = string2int (readLine ()) in

  Node (Leaf (), 2, Leaf ());

  -- Insert n random elements
  let t = insertn 1 (Leaf ()) n in

  -- Lookup the same sequence of n elements
  lookupn 1 t n;

  -- Lookup a sequence of fresh random elements
  lookupn 5 t n;

  ()
