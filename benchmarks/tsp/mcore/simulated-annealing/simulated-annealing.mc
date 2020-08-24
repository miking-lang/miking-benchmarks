include "../tsp.mc"

mexpr

-- Read input data
let input = parseTSPInput () in
let g = input.g in
let initTour = input.initTour in

-- Set up simulated annealing
let randSol = lam ns. lam state.
  match ns with [] then None () else
  let nRand = get ns (randIntU 0 (length ns)) in
  (nRand, cost nRand)
in

let decayFunc = lam temp. lam state.
  mulf temp 0.95
in

let metaSA = (SimulatedAnnealing {temp = 100.0, decayFunc = decayFunc},
              stepSA (neighbours g) randSol) in

-- Solve the problem
minimizeTSP initTour metaSA
