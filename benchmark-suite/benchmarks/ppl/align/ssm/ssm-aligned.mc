---------------------------------------
-- A model for aircraft localization --
---------------------------------------

include "math.mc"

mexpr

-- Noisy observations of position
let ysPos: [Float] = [
  603.5736741666899, 860.4207338929477, 1012.0766100484578, 1163.5339974878366,
  1540.2972028551385, 1818.1023092741882, 2045.3888580253108,
  2363.4902615131796, 2590.773153142429, 2801.9143537470927
] in

-- Constants
let holdAlt = 35000. in
let altRange = 100. in
let baseVelocity = 250. in
let basePosObsStdev = 50. in
let altStdev = 100. in

-- Priors for first position and altitude
let pos: Float = assume (Uniform 0. 1000.) in
let alt: Float = assume (Gaussian holdAlt 200.) in

-- Standard deviation in moving one position (caused by, e.g., wind differences)
let posStdev = 50. in

-- Velocity as a function of altitude
let velocity: Float -> Float = lam altitude.
  let k = divf baseVelocity holdAlt in
  minf 500. (maxf 100. (mulf k altitude))
in

-- Standard deviation of position observation as a function of altitude
let posObsStdev: Float -> Float = lam altitude.
  let m = 100. in
  let k = negf (divf basePosObsStdev holdAlt) in
  maxf 10. (addf m (mulf k altitude))
in

-- Main model function
recursive let simulate: Int -> Float -> Float -> Float =
  lam t: Int. lam pos: Float. lam alt: Float.

  -- Observe position
  let dataPos: Float = get ysPos t in
  observe dataPos (Gaussian pos (posObsStdev alt));
  resample; -- Should be added by analysis

  -- Increment time step
  let t = addi t 1 in

  -- Penalize altitude divergence of more than 100 feet from holding altitude
  (if gtf (absf (subf alt holdAlt)) altRange then
     weight (log 0.5)
   else ());

  -- Transition both position and altitude
  let pos: Float = assume (Gaussian (addf pos (velocity alt)) posStdev) in
  let alt: Float = assume (Gaussian alt altStdev) in

  -- Exit and return position after all observations have been processed
  if eqi (length ysPos) t then pos
  else simulate t pos alt
in

simulate 0 pos alt

