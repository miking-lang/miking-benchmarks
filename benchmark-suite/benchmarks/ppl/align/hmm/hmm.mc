-- Needed for inf
include "math.mc"

mexpr

-- DATA
-- We can only retrieve data from the sensor in batches of 10 discrete time steps

-- Observations of position
let ysPos: [Float] = [
  18.73789717654238,
  23.617665886435205,
  30.236990929065218,
  31.605211854872387,
  38.30572533825444,
  40.40862673437246,
  47.61811023739945,
  55.06577547998068,
  55.37143294083621,
  57.42814932929579
] in

-- Observations of altitude (less than 10 observations, not known at which time steps)
let ysAlt: [Float] = [
  73.06133041262557,
  103.86569351654443,
  106.79815380948003,
  99.17888261502746,
  84.75553135230473
] in

let pos: Float = assume (Uniform 0. 100.) in
let alt: Float = assume (Uniform 50. 100.) in

recursive let simulate: Int -> Int -> Float -> Float -> () =
  lam t: Int. lam iAlt. lam pos: Float. lam alt: Float.

  -- Observe

  let dataPos: Float = get ysPos t in
  observe dataPos (Gaussian pos 2.);
  resample;
  let t = addi t 1 in

  let iAlt: Int =
    if assume (Bernoulli 0.5) then
      if eqi (length ysAlt) iAlt then weight (negf inf); iAlt else
        let dataAlt: Float = get ysAlt iAlt in
        observe dataAlt (Gaussian alt 5.);
        resample;
        addi iAlt 1
    else iAlt
  in

  -- Transition
  let pos: Float = assume (Gaussian (addf pos 4.) 2.) in
  let alt: Float = assume (Gaussian alt 10.) in

  if eqi (length ysPos) t then
    -- If we have not seen all altitude observations, this run fails
    if lti iAlt (length ysAlt) then weight (negf inf); resample else -- TODO Not having ; resample here causes a bug in the compiler
    -- We do not return anything here, but simply run the model for
    -- estimating the normalizing constant.
    ()
  else
    simulate t iAlt pos alt
in

simulate 0 0 pos alt

