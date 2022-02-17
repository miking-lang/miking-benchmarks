
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
]

-- Observations of altitude (less than 10 observations, not known at which time steps)
let ysAlt: [Float] = [
  73.06133041262557,
  103.86569351654443,
  106.79815380948003,
  99.17888261502746,
  84.75553135230473
]

-- GENERATIVE MODEL
-- One transition model for how airplane moves horizontally
-- One transition model for how airplane moves vertically
-- Altimeter sensor has 50% failure rate (observe with 50% prob)

