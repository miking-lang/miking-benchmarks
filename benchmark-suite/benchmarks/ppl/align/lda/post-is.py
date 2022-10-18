#!/usr/bin/env python3

# Compute histogram for the three topics in the simple data LDA
# model.

import sys
import re
import math
import numpy as np
import matplotlib.pyplot as plt
import json

# Remove first line of output (accept rate)
sys.stdin.readline()

# Samples
theta1 = []
theta2 = []
theta3 = []
weights = []

for line in sys.stdin:
    line = re.sub(' +', ' ', line).rsplit(' ', 1)
    sample = line[0].split()
    theta1.append(float(sample[0]))
    theta2.append(float(sample[2]))
    theta3.append(float(sample[4]))
    weight = line[1]
    weights.append(float(weight))

m = max(weights)
weights = [math.exp(w - m) for w in weights]

# Compute histogram representation and print to stdout
counts1, bins1 = np.histogram(theta1, bins=50, range=(0,1), weights=weights)
counts2, bins2 = np.histogram(theta2, bins=50, range=(0,1), weights=weights)
counts3, bins3 = np.histogram(theta3, bins=50, range=(0,1), weights=weights)
data=json.dumps({
    "counts1": counts1.tolist(), "bins1": bins1.tolist(),
    "counts2": counts2.tolist(), "bins2": bins2.tolist(),
    "counts3": counts3.tolist(), "bins3": bins3.tolist(),
}, separators=(',', ':'))
print(data)

# Example of how to load and use the JSON-serialized data above:
# data = json.loads(data)
# plt.hist(data["bins1"][:-1], data["bins1"], weights=data["counts1"])
# plt.show()
