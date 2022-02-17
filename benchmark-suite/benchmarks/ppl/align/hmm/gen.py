#!/usr/bin/env python3

import random

STEPS = 10

POS_STDEV = 2
VELOCITY = 4
POS_OBS_STDEV = 2

ALT_STDEV = 10
ALT_OBS_STDEV = 5

def flip():
    return bool(random.getrandbits(1))

# Set up initial position and altitude
pos = [random.uniform(0,100)]
alt = [random.uniform(50,100)]
pos_obs = []
alt_obs = []

# Run for 10 time steps (configurable)
for i in range(STEPS):

    # Output observations
    pos_obs.append(random.normalvariate(pos[i], POS_OBS_STDEV))
    if flip():
        alt_obs.append(random.normalvariate(alt[i], ALT_OBS_STDEV))

    # Transition model
    pos.append(random.normalvariate(pos[i] + VELOCITY, POS_STDEV))
    alt.append(random.normalvariate(alt[i], ALT_STDEV))

    if alt[i] <= 0: print("CRASH"); break

# Print observations
print(pos_obs)
print(alt_obs)
