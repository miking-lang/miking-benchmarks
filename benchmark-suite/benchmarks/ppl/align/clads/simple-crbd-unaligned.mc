------------------------------------------------------------------------------------
-- Constant-rate birth-death model (CRBD) model, straightforward branch traversal --
------------------------------------------------------------------------------------

-- The prelude includes a few PPL helper functions
include "pplprelude.mc"

-- The tree.mc file defines the general tree structure
include "tree.mc"

-- The tree-instance.mc file includes the actual tree and the rho constant
include "tree-instance.mc"

mexpr

recursive
let goesUndetected: Float -> Float -> Float -> Float -> Bool =
  lam startTime_Mya: Float.
  lam lambda: Float.
  lam mu: Float.
  lam rho: Float.
    let eventTime_My = assume (Exponential (addf lambda mu)) in
    let currentTime_Mya = subf startTime_Mya eventTime_My in 
  --  let currentTime_Mya = subf startTime_Mya tSpeciation_My in
    let extinction = assume (Bernoulli (divf mu (addf lambda mu))) in
    if extinction then true
    else
      if ltf currentTime_Mya 0. then
        if assume (Bernoulli rho) then false
        else true
      else
        if goesUndetected currentTime_Mya lambda mu rho then
  	   goesUndetected currentTime_Mya lambda mu rho
        else false
in

-- Simulation of branch
-- returns lambda at the end of branch
recursive
let simBranch: Float -> Float -> Float -> Float -> Float -> () =
  lam startTime_Mya: Float.
  lam stopTime_Mya: Float.
  lam lambda: Float.
  lam mu: Float.
  lam rho: Float.
    let tSpeciation_My = assume (Exponential lambda) in
    let currentTime_Mya = subf startTime_Mya tSpeciation_My in
    if (ltf currentTime_Mya stopTime_Mya) then ()
    else
    if goesUndetected currentTime_Mya lambda rho then
      let w1 = weight (log 2.) in
      simBranch currentTime_Mya stopTime_Mya lambda mu rho
    else -- side branch detected
      let w2 = weight (negf inf) in
      ()
in

-- Simulating along the tree structure
recursive
let simTree: Tree -> Tree -> Float -> Float -> Float -> () =
  lam tree: Tree.
  lam parent: Tree.
  lam lambda: Float.
  lam mu: Float.
  lam rho: Float.
  
    let startTime_Mya = getAge parent in
    let stopTime_Mya = getAge tree in
    let w1 = weight( mulf (negf mu) (subf startTime_Mya stopTime_Mya) ) in
    (simBranch startTime_Mya stopTime_Mya lambda mu rho);
    (match tree with Node _ then weight (log (lambda)) else weight (log rho));
    -- resample; -- This should be added automatically by alignment analysis
  
    match tree with Node { left = left, right = right } then
      simTree left tree lambda mu rho;
      simTree right tree lambda mu rho
    else ()
in

-- Priors
let lambda = 0.2 in
let mu = 0.1 in 
-- Adjust for normalizing constant
let numLeaves = countLeaves tree in
let corrFactor =
  subf (mulf (subf (int2float numLeaves) 1.) (log 2.)) (lnFactorial numLeaves) in
weight corrFactor;
-- resample; -- This should be added automatically by alignment analysis

-- Start of the simulation along the two branches
(match tree with Node { left = left, right = right } then
   simTree left tree lambda mu rho;
   simTree right tree lambda mu rho
 else ());

-- Returns the posterior for the lambda
lambda
