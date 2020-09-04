include "../tsp.mc"

mexpr

-- Read input data
let input = parseTSPInput () in
let g = input.g in
let initTour = input.initTour in

-- Set up tabu search
let randElem = lam seq.
  match seq with [] then None ()
  else Some (get seq (randIntU 0 (length seq))) in

let randomBest = lam ns. lam state.
  match ns with [] then None () else
  let costs = map cost ns in
  let minCost = min subi costs in
  let nsCosts = zipWith (lam n. lam c. (n,c)) ns costs in
  let minNs = filter (lam t. eqi t.1 minCost) nsCosts in
  randElem minNs
in

let toursEq = lam t1. lam t2.
  setEqual (digraphEdgeEq g) t1 t2 in

let metaTabu = (TabuSearch {tabu = [initTour],
                            isTabu = lam tour. lam tabu. any (toursEq tour) tabu,
                            tabuAdd = lam assign. lam tabu. cons assign tabu,
                            tabuConvert = lam sol. sol.0},
                stepTabu (neighbours g) randomBest) in

-- Solve the problem
minimizeTSP initTour metaTabu
