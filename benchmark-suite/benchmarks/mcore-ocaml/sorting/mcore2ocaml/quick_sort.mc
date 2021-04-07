
let null = lam seq. eqi 0 (length seq)
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

let int2string = lam n.
  recursive
  let int2string_rechelper = lam n.
    if lti n 10
    then [int2char (addi n (char2int '0'))]
    else
      let d = [int2char (addi (modi n 10) (char2int '0'))] in
      concat (int2string_rechelper (divi n 10)) d
  in
  if lti n 0
  then cons '-' (int2string_rechelper (negi n))
  else int2string_rechelper n

-- Joins the strings in strs on delim
recursive
  let strJoin = lam delim. lam strs.
    if eqi (length strs) 0
    then ""
    else if eqi (length strs) 1
    then head strs
    else concat (concat (head strs) delim) (strJoin delim (tail strs))
end


-- Linear congruential generator: https://en.wikipedia.org/wiki/Linear_congruential_generator
let lcg = lam m. lam a. lam c. lam x.
  modi (addi (muli a x) c) m

-- Generates a random number between 0 and 1073741789
-- Parameters to LCG taken from
-- https://www.ams.org/journals/mom/1999-68-225/S0025-5718-99-00996-5/S0025-5718-99-00996-5.PDP
let rand = lam seed.
  let r = lcg 1073741789 771645345 0 seed in
  r

let randList = lam n.
  create n (lam i. rand (addi i 1))

let mapi = lam f. lam seq.
  recursive let work = lam i. lam f. lam seq.
      if null seq then []
      else cons (f i (head seq)) (work (addi i 1) f (tail seq))
  in
  work 0 f seq

let map = lam f. mapi (lam. lam x. f x)

recursive
  let filter = lam p. lam seq.
  if null seq then []
  else if p (head seq) then cons (head seq) (filter p (tail seq))
  else (filter p (tail seq))
end

let partition = (lam p. lam seq.
  (filter p seq, filter (lam q. if p q then false else true) seq))

recursive
  let quickSort = lam seq.
    if null seq then seq else
    let h = head seq in
    let t = tail seq in
    let lr = partition (lam x. lti x h) t in
    concat (quickSort lr.0) (cons h (quickSort lr.1))
end

mexpr
let n = readLine () in

let l = randList (string2int n) in

let sorted = quickSort l in

()
--print (strJoin " " (map int2string sorted))
