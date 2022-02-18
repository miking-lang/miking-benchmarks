#!/usr/bin/env python3

import random
import pprint

STEPS = 10
ALTITUDE_HOLD=35000

POS_STDEV = 50

BASE_VELOCITY = 250
def velocity(altitude):
    k = BASE_VELOCITY/ALTITUDE_HOLD
    return min(500,max(100,k*altitude))

BASE_POS_OBS_STDEV = 50
def pos_obs_stdev(altitude):
    m = 100
    k = -BASE_POS_OBS_STDEV/ALTITUDE_HOLD
    return max(10.0,(m+k*altitude))

ALT_STDEV = 100

def flip(): return bool(random.getrandbits(1))

# Set up initial position and altitude
pos = [random.uniform(0,1000)]
alt = [random.normalvariate(ALTITUDE_HOLD,200)]
pos_obs = []

# Run for 10 time steps (configurable)
for i in range(STEPS):

    # Output observations
    pos_obs.append(random.normalvariate(pos[i], pos_obs_stdev(alt[i])))

    # Transition model
    pos.append(random.normalvariate(pos[i] + velocity(alt[i]), POS_STDEV))
    alt.append(random.normalvariate(alt[i], ALT_STDEV))


# Print observations
print("POSITION")
pprint.pprint(pos)
print("OBSERVED POSITION")
pprint.pprint(pos_obs)
print("ALTITUDE")
pprint.pprint(alt)
