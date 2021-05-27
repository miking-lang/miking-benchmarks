
include "bool.mc"
include "math.mc"


-- These function are right now placeholders.
-- The CorePPL to RootPPL compiler should translate this
-- to the correct functions.
let log: Float -> Float = lam x: Float. x
let int2float: Int -> Float = lam x: Int. (x; 1.0)

-- Other functions that might need special treatment are:
--  'and', 'inf',

-- Help function that is needed in models
recursive
let lnFactorial: Int -> Float = lam n: Int.
  if eqi n 1 then 0.
  else addf (log (int2float n)) (lnFactorial (subi n 1))
end
