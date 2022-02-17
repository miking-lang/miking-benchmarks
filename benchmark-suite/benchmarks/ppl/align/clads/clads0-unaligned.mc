------------------------------------------------------------------------------------
-- The ClaDogenetic Diversification Shifts model with 0 extinction (ClaDS0) model --
------------------------------------------------------------------------------------

-- The prelude includes a few PPL helper functions
include "pplprelude.mc"

-- The tree.mc file defines the general tree structure
include "tree.mc"

-- The tree-instance.mc file includes the actual tree and the rho constant
include "tree-instance.mc"

mexpr

let MAX_M = 10e5 in
let MIN_M = succ 0 in-- Smallest representable floating point number?

-- ClaDS0 goes undetected.
-- TODO Perhaps a good idea to invert the semantics from undetected to detected?
recursive
let clads0GoesUndetected: Float -> Float -> Float -> Float -> Float -> Float -> Bool =
    lam startTime_Mya: Float.
    lam lambda0: Float.
    lam m: Float. -- Multiplier
    lam logAlpha: Float. -- logarithm of alpha
    lam sigma2: Float. -- Variance
    lam rho: Float.

    -- Guard: m is not allowed to exceed MAX_M or be 0.
    if (gtf m MAX_N) or (ltf m MIN_M) then false -- m > MAX_M or m < MIN_M
    else        
    	let tSpeciation_My = assume (Exponential (m*lambda0)) in
	let currentTime_Mya = startTime_Mya - tSpeciation_My in
	let cond =
            if (ltf currentTime_Mya 0) then -- currentTime_Mya < 0
 	    (eqBool (assume (Bernoulli rho)) true) -- detected
        else false
        in
    if cond then false
    else    
      -- @Daniel: Check parametrization of normal distribution and exponentiation.
      let m1 = m * exp assume (Normal (logAlpha, sigma2)) in
      let m2 = m * exp assume (Normal (logAlpha, sigma2)) in 

      if clads0GoesUndetected currentTime_Mya lambda0 m1 logAlpha sigma2 rho then
        if clads0GoesUndetected currentTime_Mya lambda0 m2 logAlpha sigma2 rho then true
	else false
      else false
in

-- Simulation of branch
recursive
let clads0SimBranch: Float -> Float -> Float -> Float -> Float -> Float -> Float -> Float =
  lam startTime_Mya: Float.
  lam stopTime_Mya: Float.
  lam lambda0: Float.
  lam m: Float. -- multiplier
  lam logAlpha: Float.
  lam sigma2: Float.
  lam rho: Float.

  -- Guard: m is not allowed to exceed MAX_M or be 0.
  if (gtf m MAX_N) or (ltf m MIN_M) then
     let w0 = weight (negf inf) in
     m
  else 
    let tSpeciation_My = assume (Exponential (m*lambda0)) in
    let currentTime_Mya = startTime_Mya - tSpeciation_My in
    let cond =
      if (ltf currentTime_Mya 0) then -- currentTime_Mya < 0
        (eqBool (assume (Bernoulli rho)) true) -- detected
      else false
    in
    if cond then m -- factor in the end
    else
      let m1 = m * exp assume (Normal (logAlpha, sigma2)) in
      if clads0GoesUndetected currentTime_Mya lambda0 m1 logAlpha sigma2 rho then
        let m2 = m * exp assume (Normal (logAlpha, sigma2)) in 
        let w1 = weight (log 2.) in
	clads0SimBranch currentTime_Mya stopTime_Mya lambda0 m2 logAlpha sigma2 rho
      else -- side branch detected
        let w2 = weight (negf inf) in
        ()
in

-- Simulating along the tree structure
recursive
let clads0SimTree: Tree -> Tree -> Float -> Float -> Float -> Float -> Float -> () =
    lam tree: Tree.
    lam parent: Tree.
    lam lambda0: Float.
    lam m: Float.
    lam logAlpha: Float.
    lam sigma2: Float.
    lam rho: Float.

    let startTime_Mya = getAge parent in
    let stopTime_Mya = getAge tree in
    let mEnd = clads0SimBranch startTime_Mya stopTime_Mya lambda0 m2 logAlpha sigma2 rho

    (match tree with Node _ then weight(log mEnd*lambda) else weight(log rho));
    -- resample; -- This should be added automatically by alignment analysis

    match tree with Node { left = left, right = right } then
      clads0SimTree left tree lambda0 mEnd logAlpha sigma2 rho;
      clads0SimTree right tree lambda0 mEnd logAlpha sigma2 rho
    else ()
in

-- Priors
let lambda0 = 0.2 in
let logAlpha = -0.3 in
let sigma2 = 0.1 in
let m = 1.0 in

-- Adjust for normalizing constant
let numLeaves = countLeaves tree in
let corrFactor =
  subf (mulf (subf (int2float numLeaves) 1.) (log 2.)) (lnFactorial numLeaves) in
weight corrFactor;
-- resample; -- This should be added automatically by alignment analysis

-- Start of the simulation along the two branches
(match tree with Node { left = left, right = right } then
  clads0SimTree left tree lambda0 m logAlpha sigma2 rho;
  clads0SimTree right tree lambda0 m logAlpha sigma2 rho
else ());

lambda0

-- Returns the posterior for the lambda
