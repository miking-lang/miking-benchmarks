------------------------------------------------
-- The Constant-Rate Birth-Death (CRBD) model --
------------------------------------------------

-- The prelude includes a few PPL helper functions
include "pplprelude.mc"

-- The tree.mc file defines the general tree structure
include "tree.mc"

-- The tree-instance.mc file includes the actual tree and the rho constant
include "tree-instance-example.mc"

mexpr

-- Simulating along the tree structure
recursive
let simTree: Tree -> Tree -> Float -> () =
  lam tree: Tree.
  lam parent: Tree.
  lam lambda: Float.
  -- probability of exactly one speciation at end of branch, 0 at tips
  let branchEndProb = match tree with Node _ then log lambda else log 1.0 in

  let startTime = getAge parent in
  let stopTime = getAge tree in
  -- no speciation events along the branch
  let branchProb = mulf (negf lambda) (subf startTime stopTime) in

  weight (addf branchEndProb branchProb);
  resample;

  match tree with Node { left = left, right = right } then
    simTree left tree lambda;
    simTree right tree lambda
  else ()
in

-- Priors
let lambda = assume (Gamma 1.0 1.0) in
let mu = assume (Gamma 1.0 0.5) in

-- Start of the simulation along the two branches
(match tree with Node { left = left, right = right } then
  simTree left tree lambda;
  simTree right tree lambda

else ());

lambda

-- Returns the posterior for the lambda
