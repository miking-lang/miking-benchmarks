------------------------------------------------------------------
-- The ClaDogenetic Diversification Shifts model (ClaDS2) model --
------------------------------------------------------------------

-- The prelude includes a few PPL helper functions
include "pplprelude.mc"

-- The tree.mc file defines the general tree structure
include "tree.mc"

-- The tree-instance.mc file includes the actual tree and the rho constant
include "tree-instance.mc"

mexpr

-- Multiplier guards
let maxM = 10e5 in
let minM = 0. in

-- Clads2 goes undetected.
recursive
let clads2GoesUndetected: Float -> Float -> Float -> Float
                            -> Float -> Float -> Float -> Bool =
  lam startTime_Mya: Float.
  lam lambda0: Float.
  lam mu0: Float.
  lam m: Float. -- Multiplier
  lam logAlpha: Float. -- Logarithm of alpha
  lam sigma: Float. -- Standard deviation
  lam rho: Float.

    -- Guard: m is not allowed to exceed maxM or be 0.
    if or (gtf m maxM) (leqf m minM) then false
    else
      let eventTime_My =
        assume (Exponential (addf (mulf m lambda0) (mulf m mu0))) in
      let currentTime_Mya = subf startTime_Mya eventTime_My in
      if ltf currentTime_Mya 0. then
        if assume (Bernoulli rho) then false
        else true
      else
	let extinction =
          assume (Bernoulli (divf (mulf m mu0)
                    (addf (mulf m lambda0) (mulf m mu0)))) in
	if extinction then true
	else
          let m1 = mulf m (exp (assume (Gaussian logAlpha sigma))) in
          let m2 = mulf m (exp (assume (Gaussian logAlpha sigma))) in
          if clads2GoesUndetected currentTime_Mya
               lambda0 mu0 m1 logAlpha sigma rho then
            clads2GoesUndetected currentTime_Mya
              lambda0 mu0 m2 logAlpha sigma rho
          else false
in

-- Simulation of branch
recursive
let simBranch: Float -> Float -> Float -> Float
                 -> Float -> Float -> Float -> Float -> Float =
  lam startTime_Mya: Float.
  lam stopTime_Mya: Float.
  lam lambda0: Float.
  lam mu0: Float.
  lam m: Float. -- multiplier
  lam logAlpha: Float.
  lam sigma: Float.
  lam rho: Float.

    -- Guard: m is not allowed to exceed maxM or be 0.
    if or (gtf m maxM) (ltf m minM) then
       let w0 = weight (negf inf) in
       m
    else
      let tSpeciation_My = assume (Exponential (mulf m lambda0)) in
      let currentTime_Mya = subf startTime_Mya tSpeciation_My in
      let branchLength_My = subf startTime_Mya stopTime_Mya in
      if (ltf currentTime_Mya stopTime_Mya) then
        let w1 = weight (mulf (negf (mulf m mu0)) branchLength_My) in
        m
      else
        let m1 = mulf m (exp (assume (Gaussian logAlpha sigma))) in
        if clads2GoesUndetected currentTime_Mya lambda0
             mu0 m1 logAlpha sigma rho then
          let m2 = mulf m (exp (assume (Gaussian logAlpha sigma))) in
          let w2 = weight (log 2.) in
  	let w3 = weight (mulf (negf (mulf m mu0)) tSpeciation_My) in
          simBranch currentTime_Mya stopTime_Mya
            lambda0 mu0 m2 logAlpha sigma rho
        else -- side branch detected
          let w4 = weight (negf inf) in
          m
in

-- Simulating along the tree structure
recursive
let simTree: Tree -> Tree -> Float -> Float
               -> Float -> Float -> Float -> Float -> () =
  lam tree: Tree.
  lam parent: Tree.
  lam lambda0: Float.
  lam mu0: Float.
  lam m: Float.
  lam logAlpha: Float.
  lam sigma: Float.
  lam rho: Float.

    let startTime_Mya = getAge parent in
    let stopTime_Mya = getAge tree in

    let mEnd =
      simBranch startTime_Mya stopTime_Mya lambda0 mu0 m logAlpha sigma rho in
    (match tree with Node _
     then weight (log (mulf mEnd lambda0)) else weight (log rho));
    -- resample; -- This should be added automatically by alignment analysis

    let m1 = mulf mEnd (exp (assume (Gaussian logAlpha sigma))) in
    let m2 = mulf mEnd (exp (assume (Gaussian logAlpha sigma))) in
    match tree with Node { left = left, right = right } then
      simTree left tree lambda0 mu0 m1 logAlpha sigma rho;
      simTree right tree lambda0 mu0 m2 logAlpha sigma rho
    else ()
in

-- Priors
let lambda0 = 0.2 in
let mu0 = 0.1 in
let logAlpha = negf 0.3 in
let sigma = sqrt 0.1 in
let m = 1.0 in

-- Adjust for normalizing constant
let numLeaves = countLeaves tree in
let corrFactor =
  subf (mulf (subf (int2float numLeaves) 1.) (log 2.)) (lnFactorial numLeaves) in
weight corrFactor;
-- resample; -- This should be added automatically by alignment analysis

let m1 = mulf m (exp (assume (Gaussian logAlpha sigma))) in
let m2 = mulf m (exp (assume (Gaussian logAlpha sigma))) in

-- Start of the simulation along the two branches
(match tree with Node { left = left, right = right } then
   simTree left tree lambda0 mu0 m1 logAlpha sigma rho;
   simTree right tree lambda0 mu0 m2 logAlpha sigma rho
 else ());

-- Returns nothing, as the current model is only used to compute the
-- normalizing constant
()
