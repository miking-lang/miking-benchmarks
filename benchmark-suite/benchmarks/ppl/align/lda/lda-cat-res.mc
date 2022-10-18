include "common.mc"
include "string.mc"
include "seq.mc"

include "data-simple-cat.mc"

mexpr

-- Model
let alpha: [Float] = make numtopics 1. in
let beta: [Float] = make vocabsize 1. in
let phi = create numtopics (lam. assume (Dirichlet beta)) in
let theta = create numdocs (lam. assume (Dirichlet alpha)) in
repeati (lam w.
    let z = assume (Categorical (get theta (get docids w))) in
    observe (get docs w) (Categorical (get phi z))
  ) (length docs);

let str = foldl (lam acc. lam e. join [acc,float2string e," "]) "" (get theta 0) in
let str = foldl (lam acc. lam e. join [acc,float2string e," "]) str (get theta 1) in
let str = foldl (lam acc. lam e. join [acc,float2string e," "]) str (get theta 2) in
let str = foldl (lam acc. lam e. join [acc,float2string e," "]) str (get phi 0) in
foldl (lam acc. lam e. join [acc,float2string e," "]) str (get phi 1)
