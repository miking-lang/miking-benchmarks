----------------------------------------------------------------------------
-- The SEIR model from https://docs.birch.sh/examples/VectorBorneDisease/ --
----------------------------------------------------------------------------

include "math.mc"

mexpr

let hNu: Float = 0. in
let hMu: Float = 1. in
let hLambda: Float = assume (Beta 1. 1.) in
let hDelta: Float =
  assume (Beta (addf 1. (divf 2. 4.4)) (subf 3. (divf 2. 4.4))) in
let hGamma: Float =
  assume (Beta (addf 1. (divf 2. 4.5)) (subf 3. (divf 2. 4.5))) in

let mNu: Float = divf 1. 7. in
let mMu: Float = divf 6. 7. in
let mLambda: Float = assume (Beta 1. 1.) in
let mDelta: Float =
  assume (Beta (addf 1. (divf 2. 6.5)) (subf 3. (divf 2. 6.5))) in
let mGamma: Float = 0. in

let rho: Float = assume (Beta 1. 1.) in
let z: Int = 0 in

let n: Int = 7370 in
let hI: Int = addi 1 (assume (Poisson 5.0)) in
let hE: Int = assume (Poisson 5.0) in
let hR: Int =
  floorfi (assume (Uniform 0. (int2float (addi 1 (subi (subi n hI) hE))))) in
let hS: Int = subi (subi (subi n hE) hI) hR in

let hDeltaS: Int = 0 in
let hDeltaE: Int = hE in
let hDeltaI: Int = hI in
let hDeltaR: Int = 0 in

let u: Float = assume (Uniform (negf 1.) 2.) in
let mS: Int = floorfi (mulf (int2float n) (pow 10. u)) in
let mE: Int = 0 in
let mI: Int = 0 in
let mR: Int = 0 in

let mDeltaS: Int = 0 in
let mDeltaE: Int = 0 in
let mDeltaI: Int = 0 in
let mDeltaR: Int = 0 in

-- Observations, -1 indicates the lack of an observation
let null = negi 1 in
let ys: [Int] = [ 1, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 2, 0, 0, 1, 0, 0, 2, 1, 4, 2, 3, 2, 2, 4, 1, 3, 3, 4, 3, 3, 9, 1, 1, 7, 5, 4, 1, 2, 4, 7, 3, 6, 6, 4, 8, 6, 7, 2, 6, 7, 5, 7, 9, 10, 14, 9, 4, 5, 7, 10, 11, 17, 6, 13, 13, 14, 13, 12, 12, 15, 16, 12, 14, 11, 17, 10, 10, 16, 12, 17, 29, 21, 21, 25, 17, 12, 18, 11, 12, 10, 18, 8, 14, 10, 15, 16, 8, 7, 5, 7, 5, 5, 6, 11, 10, 5, 4, 9, 6, 1, 6, 3, 6, 4, 3, 5, 1, 8, 2, 9, 4, 5, 4, 3, 3, 4, 4, 3, 3, 4, 5, 2, 5, 4, 2, 6, 4, 2, 0, 4, 2, 1, 1, 1, 2, 3, 3, 3, 0, 3, 2, 1, 0, 1, 0, 0, 1, 2, 2, 1, 0, 1, 1, 1, null, null, null, null, null, null, 0, null, null, null, null, null, null, 0 ] in

recursive let simulate:
  Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> ()
  =
  lam t: Int.
  lam hSP: Int.
  lam hEP: Int.
  lam hIP: Int.
  lam hRP: Int.
  lam mSP: Int.
  lam mEP: Int.
  lam mIP: Int.
  lam mRP: Int.
  lam zP: Int.

    -- Humans
    let hN: Int = addi (addi (addi hSP hEP) hIP) hRP in
    let hTau: Int =
      assume (Binomial hSP (subf 1. (exp (negf (divf
                                                (int2float mIP)
                                                (int2float hN)))))) in
    let hdeltaE: Int = assume (Binomial hTau hLambda) in
    let hDeltaI: Int = assume (Binomial hEP hDelta) in
    let hDeltaR: Int = assume (Binomial hIP hGamma) in
    let hS: Int = subi hSP hDeltaE in
    let hE: Int = subi (addi hEP hDeltaE) hDeltaI in
    let hI: Int = subi (addi hIP hDeltaI) hDeltaR in
    let hR: Int = addi hRP hDeltaR in

    -- Mosquitos
    let mTau: Int =
      assume (Binomial mSP (subf 1. (exp (negf (divf
                                               (int2float hIP)
                                               (int2float hN)))))) in
    let mN: Int  = addi (addi (addi mSP mEP) mIP) mRP in
    let mdeltaE: Int = assume (Binomial mTau mLambda) in
    let mDeltaI: Int = assume (Binomial mEP mDelta) in
    let mDeltaR: Int = assume (Binomial mIP mGamma) in
    let mS: Int = subi mSP mDeltaE in
    let mE: Int = subi (addi mEP mDeltaE) mDeltaI in
    let mI: Int = subi (addi mIP mDeltaI) mDeltaR in
    let mR: Int = addi mRP mDeltaR in

    let mS: Int = assume (Binomial mS mMu) in
    let mE: Int = assume (Binomial mE mMu) in
    let mI: Int = assume (Binomial mI mMu) in
    let mR: Int = assume (Binomial mR mMu) in

    let mDeltaS: Int = assume (Binomial mN mNu) in
    let mS: Int = addi mS mDeltaS in

    -- Observation
    let z: Int = addi zP hDeltaI in
    let y: Int = get ys t in
    let z: Int = if neqi (negi 1) y then observe y (Binomial z rho); resample; 0 else z in

    -- Recurse
    let tNext: Int = addi t 1 in
    if eqi (length ys) t then
      -- We do not return anything here, but simply run the model for
      -- estimating the normalizing constant.
      ()
    else
      simulate tNext hS hE hI hR mS mE mI mR z
in

simulate 0 hS hE hI hR mS mE mI mR z
