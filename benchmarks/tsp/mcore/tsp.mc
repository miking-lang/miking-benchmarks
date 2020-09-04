-- Common definitions for TSP benchmarks

include "local-search.mc"
include "string.mc"

-- "[a, b, c]" -> [a, b, c]
let parseVertices = lam str.
  -- Remove brackets
  let noBrackets = get (strSplit "]" (get (strSplit "[" str) 1)) 0 in
  match noBrackets  with [] then [] else
  let commaSplit = strSplit "," noBrackets in
  map strTrim commaSplit

utest parseVertices "[]" with []
utest parseVertices "  [1] " with ["1"]
utest parseVertices " [1,  2]  " with ["1", "2"]

-- "[(a,b,1),(c,d,2)]" -> [(a,b,1),(c,d,2)]
let parseEdges = lam str.
  let noBrackets = get (strSplit "]" (get (strSplit "[" str) 1)) 0 in
  match noBrackets with [] then [] else
  let rawTuples = tail (strSplit "(" noBrackets) in
  map (lam s. let spl = map strTrim (strSplit "," s)
              in (get spl 0, get spl 1,
                  string2int (get (strSplit ")" (get spl 2)) 0)))
      rawTuples

utest parseEdges " []  " with []
utest parseEdges " [(a,  b, 1)  , (c,d,  42)] " with [("a","b",1),("c","d",42)]

let parseTSPInput =
  let vs = parseVertices (readLine ()) in
  let es = parseEdges (readLine ()) in
  let initTour = parseEdges (readLine ()) in

  {g = digraphAddEdges es (digraphAddVertices vs (digraphEmpty eqstr eqi)),
   initTour = initTour}


-- Neighbourhood function: replace 2 edges by two others s.t. tour is still a
-- Hamiltonian circuit
let neighbours = lam g. lam state.
  let curSol = state.cur in
  let tour = curSol.0 in

  let tourHasEdge = lam v1. lam v2.
    any (lam e. or (and (eqstr v1 e.0) (eqstr v2 e.1))
                   (and (eqstr v1 e.1) (eqstr v2 e.0))) tour in

  -- Find replacing edges for 'e12' and 'e34'
  let exchange = lam e12. lam e34.
    let v1 = e12.0 in
    let v2 = e12.1 in
    let v3 = e34.0 in
    let v4 = e34.1 in

    let v1v3 = digraphEdgesBetween v1 v3 g in
    let v2v4 = digraphEdgesBetween v2 v4 g in

    let res =
      match (v1v3, v2v4) with ([],_) | (_,[]) then None () else
      match (v1v3, v2v4) with ([e13], [e24]) then
        if not (tourHasEdge v1 v3) then Some (e12, e34, e13, e24)
        else None ()
      else
        error "Expected at most one edge between any two nodes"
    in res
  in

  let neighbourFromExchange = lam oldEdgs. lam newEdgs. lam tour.
    let equal = digraphEdgeEq g in
    setUnion equal newEdgs (setDiff equal tour oldEdgs)
  in

  let possibleExchanges =
    foldl (lam outerAcc. lam e1.
           concat outerAcc
           (foldl (lam innerAcc. lam e2.
                     let e = exchange e1 e2 in
                     match e with Some r then cons r innerAcc else innerAcc)
                  []
            tour))
          []
          tour
   in map (lam ex. neighbourFromExchange [ex.0,ex.1] [ex.2,ex.3] tour) possibleExchanges

-- Cost function
let cost = lam tour.
  foldl (lam sum. lam edge. addi sum edge.2) 0 tour

-- Stop condition
let terminate = lam state.
  geqi state.iter 10

-- Print on each iteration
let printIter = lam state. print (strJoin "" ["Iter: ", int2string state.iter, ", ",
                                                              "Best: ", int2string state.inc.1, "\n"])

let minimizeTSP = lam initTour. lam meta.
  minimize terminate printIter (initSearchState (initTour, cost initTour) subi) meta
