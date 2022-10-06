include "common.mc"
include "string.mc"
include "seq.mc"
include "ext/dist-ext.mc"

include "data-simple.mc"

mexpr

let alpha: [Float] = make numtopics 1. in
let beta: [Float] = make vocabsize 1. in
let phi = create numtopics (lam. assume (Dirichlet beta)) in
let theta = create numdocs (lam. assume (Dirichlet alpha)) in
repeati (lam w.
    let word = get docs w in
    let counts = assume (Multinomial word.1 (get theta (get docids w))) in
    iteri (lam z. lam e.
        weight (mulf (int2float e)
                  (bernoulliLogPmf (get (get phi z) word.0) true))
      ) counts
  ) (length docs);

let str = foldl (lam acc. lam e. join [acc,float2string e," "]) "" (get theta 0) in
let str = foldl (lam acc. lam e. join [acc,float2string e," "]) str (get theta 1) in
let str = foldl (lam acc. lam e. join [acc,float2string e," "]) str (get theta 2) in
let str = foldl (lam acc. lam e. join [acc,float2string e," "]) str (get phi 0) in
foldl (lam acc. lam e. join [acc,float2string e," "]) str (get phi 1)
-- get (get theta 0) 0
