
-- The prelude includes a few PPL helper functions
include "pplprelude.mc"
-- The tree.mc file defines a tree structure
include "tree.mc"
-- The tree-instance.mc file includes the actual tree
include "tree-instance.mc"
mexpr

-- CRDB goes undetected, including iterations. Mutually recursive functions.
recursive
  let iter = lam n. lam startTime. lam branchLength. lam lambda. lam mu. lam rho.
    if eqi n 0 then
      true
    else
      let eventTime = assume (Uniform (subf startTime branchLength) startTime) in
      if crbdGoesUndetected eventTime lambda mu rho then
        iter (subi n 1) startTime branchLength lambda mu rho
      else
        false

  let crbdGoesUndetected = lam startTime. lam lambda. lam mu. lam rho.
     let duration = assume (Exponential mu) in
     if and (gtf duration startTime) (eqi (assume (Bernoulli 0.5)) 1) then
       false
     else
       let branchLength = if ltf duration startTime then duration else startTime in
       let n = assume (Poisson (mulf lambda branchLength)) in
       iter n startTime branchLength lambda mu rho
in

-- Simulation of branch
recursive
let simBranch = lam n. lam startTime. lam stopTime. lam lambda. lam mu. lam rho.
  if eqi n 0 then 0.
  else
    let currentTime = assume (Uniform stopTime startTime) in
    if crbdGoesUndetected currentTime lambda mu rho then
      let v = simBranch (subf n 1) startTime stopTime lambda mu rho in
      addf v (log 2.)
    else
      negf inf
in

-- Simulating along the tree structure
recursive
let simTree = lam tree. lam parent. lam lambda. lam mu. lam rho.
  let lnProb1 = mulf (negf mu) (subf (getAge parent) (getAge tree)) in
  let lnProb2 = match tree with Node _ then log lambda else log rho in

  let startTime = getAge parent in
  let stopTime = getAge tree in
  let n = assume (Poisson (mulf lambda (subf startTime stopTime))) in
  let lnProb3 = simBranch n startTime stopTime lambda mu rho in

  weight (addf lnProb1 (addf lnProb2 lnProb3));

  match tree with Node _ then
    simTree tree.left tree lambda mu rho;
    simTree tree.right tree lambda mu rho
  else ()
in

-- Priors
let lambda = assume (Gamma 1.0 1.0) in
let mu = assume (Gamma 1.0 0.5) in

-- Adjust for normalizing constant
let numLeaves = countLeaves tree in
let corrFactor = subf (mulf (subf numLeaves 1.) (log 2.)) (lnFactorial numLeaves) in
weight corrFactor;

-- Start of the simulation along the two branches
simTree tree.left tree lambda mu rho;
simTree tree.right tree lambda mu rho;

-- Returns the posterior for the lambda
lambda
