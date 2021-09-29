---------------------------------------------------------------------------
-- The SIR model from https://www.birch.sh/getting-started/markov-model/ --
---------------------------------------------------------------------------

include "math.mc"

mexpr

let lambda = 10. in
let delta = assume (Beta 2. 2.) in
let gamma = assume (Beta 2. 2.) in

let s = 760 in
-- let i = 3 in -- NOTE: Not really needed
let r = 0 in

let iObs = [6,25,73,222,294,258,237,191,125,69,27,11,4] in

recursive let simulate: Int -> Int -> Int -> Int = lam t. lam sPrev. lam rPrev.
  let iPrev: Int = get iObs (negi t 1) in
  let tau = assume (Binomial sPrev
    (subf 1.0 (exp (divf
      (int2float (negi (muli lambda iPrev)))
      (addf (addf (int2float sPrev) (int2float iPrev)) (int2float rPrev)))))) in
  let iDelta = assume (Binomial tau delta) in
  let rDelta = assume (Binomial iPrev gamma) in

  let s = subi sPrev iDelta in
  let i: Int = get iObs t in
  (if eqi i (subi (addi iPrev iDelta) rDelta) then () else weight (negf inf));
  resample;
  let r = addi rPrev rDelta in

  let t = addi t 1 in
  if eqi (length iObs) t then
    -- Return only the last s for now. In reality, we would want keep track of
    -- and return all s and r
    s
  else
    simulate t s r
in

simulate 0 s r
