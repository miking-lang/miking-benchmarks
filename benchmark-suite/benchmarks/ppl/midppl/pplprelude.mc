
include "bool.mc"
include "math.mc"


-- These functions are right now identity functions.
-- The CorePPL to RootPPL compiler should translate this
-- to the correct functions
let log = lam x. x


-- Other functions that might need special treatment are:
--  'and', 'inf',
