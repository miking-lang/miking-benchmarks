
mexpr

let null = negi 1

-- DATA
-- We can only retrieve data from the sensor in batches of 10 discrete time steps
-- Complete (10 time steps)
let ysPos: [Int] = [ obs1, obs2, obs3, obs4, ... ]
-- Less than 10 observations. Occurred in order, but not known at which time steps
let ysAlt: [Int] = [ obs1, obs2, ... ]

-- GENERATIVE MODEL
-- One transition model for how airplane moves horizontally
-- One transition model for how airplane moves vertically
-- Altimeter sensor has 50% failure rate (observe with 50% prob)

-- TODO Write everything in Python to generate some data
