
include "bool.mc"
include "math.mc"


-- These functions are right now identity functions.
-- The CorePPL to RootPPL compiler should translate this
-- to the correct functions
let log = lam x. x


-- Other functions that might need special treatment are:
--  'and', 'inf',

-- Help function that is needed in models
recursive
let lnFactorial = lam n.
  if eqi n 1 then 0.
  else addf (log (int2float n)) (lnFactorial (subi n 1))
end
