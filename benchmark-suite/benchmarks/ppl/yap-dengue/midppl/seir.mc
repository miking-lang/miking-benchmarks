----------------------------------------------------------------------------
-- The SEIR model from https://docs.birch.sh/examples/VectorBorneDisease/ --
----------------------------------------------------------------------------

include "math.mc"

mexpr

let hNu = 0. in
let hMu = 0. in
let hLambda = assume (Beta 1. 1.) in
let hDelta = assume (Beta (addf 1. (divf 2. 4.4)) (subf 3. (divf 2. 4.4))) in
let hGamma = assume (Beta (addf 1. (divf 2. 4.5)) (subf 3. (divf 2. 4.5))) in

let mNu = divf 1. 7. in
let mMu = divf 6. 7. in
let mLambda = assume (Beta 1. 1.) in
let mDelta = assume (Beta (addf 1. (divf 2. 6.5)) (subf 3. (divf 2. 6.5))) in
let mGamma = 0. in

let rho = assume (Beta 1. 1.) in
let z = 0 in

let n = 7370 in
let hI = addi 1 (assume (Poisson 5.0)) in
let hE = assume (Poisson 5.0) in
let hR = floorfi (assume (Uniform 0. (int2float (addi 1 (subi (subi n hI) hE))))) in
let hS = subi (subi (subi n hE) hI) hR in

let hDeltaS = 0 in
let hDeltaE = hE in
let hDeltaI = hI in
let hDeltaR = 0 in

let u = assume (Uniform (negf 1.) 2.) in
let mS: Float = mulf (int2float n) (pow 10. u) in
let mE = 0 in
let mI = 0 in
let mR = 0 in

let mDeltaS = 0 in
let mDeltaE = 0 in
let mDeltaI = 0 in
let mDeltaR = 0 in

-- Observations, -1 indicates the lack of an observation
let ys = [ 1, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 2, 0, 0, 1, 0, 0, 2, 1, 4, 2, 3, 2, 2, 4, 1, 3, 3, 4, 3, 3, 9, 1, 1, 7, 5, 4, 1, 2, 4, 7, 3, 6, 6, 4, 8, 6, 7, 2, 6, 7, 5, 7, 9, 10, 14, 9, 4, 5, 7, 10, 11, 17, 6, 13, 13, 14, 13, 12, 12, 15, 16, 12, 14, 11, 17, 10, 10, 16, 12, 17, 29, 21, 21, 25, 17, 12, 18, 11, 12, 10, 18, 8, 14, 10, 15, 16, 8, 7, 5, 7, 5, 5, 6, 11, 10, 5, 4, 9, 6, 1, 6, 3, 6, 4, 3, 5, 1, 8, 2, 9, 4, 5, 4, 3, 3, 4, 4, 3, 3, 4, 5, 2, 5, 4, 2, 6, 4, 2, 0, 4, 2, 1, 1, 1, 2, 3, 3, 3, 0, 3, 2, 1, 0, 1, 0, 0, 1, 2, 2, 1, 0, 1, 1, 1, negi 1, negi 1, negi 1, negi 1, negi 1, negi 1, 0, negi 1, negi 1, negi 1, negi 1, negi 1, negi 1, 0 ] in

recursive let simulate:
  Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Unit
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
    let hN = addi (addi (addi hSP hEP) hIP) hRP in
    let hTau = assume (Binomial hSP (subf 1. (exp (negf (divf mIP hN))))) in
    let hdeltaE = assume (Binomial hTau hLambda) in
    let hDeltaI = assume (Binomial hEP hDelta) in
    let hDeltaR = assume (Binomial hIP hGamma) in
    let hS = subi hSP hDeltaE in
    let hE = subi (addi hEP hDeltaE) hDeltaI in
    let hI = subi (addi hIP hDeltaI) hDeltaR in
    let hR = addi hRP hDeltaR in

    -- Mosquitos
    let mTau = assume (Binomial mSP (subf 1. (exp (negf (divf hIP hN))))) in
    let mN = addi (addi (addi mSP mEP) mIP) mRP in
    let mTau = assume (Binomial mSP (subf 1. (exp (negf (divf mIP mN))))) in
    let mdeltaE = assume (Binomial mTau mLambda) in
    let mDeltaI = assume (Binomial mEP mDelta) in
    let mDeltaR = assume (Binomial mIP mGamma) in
    let mS = subi mSP mDeltaE in
    let mE = subi (addi mEP mDeltaE) mDeltaI in
    let mI = subi (addi mIP mDeltaI) mDeltaR in
    let mR = addi mRP mDeltaR in
    let mS = assume (Binomial mS mMu) in
    let mE = assume (Binomial mE mMu) in
    let mI = assume (Binomial mI mMu) in
    let mR = assume (Binomial mR mMu) in
    let mDeltaS = assume (Binomial mN mNu) in
    let mS = addi mS mDeltaS in

    -- Observation
    let z = addi zP hDeltaI in
    let y = get ys t in
    let z = if neqi (negf 1) y then observe y (Binomial z rho); 0 else z in

    -- Recurse
    let tNext = addi t 1 in
    if eqi (length ys) t then
      -- We do not return anything here, but simply run the model for
      -- estimating the normalizing constant.
      ()
    else
      simulate tNext hS hE hI hR mS mE mI mR z
in

simulate 0 hS hE hI hR mS mE mI mR z
