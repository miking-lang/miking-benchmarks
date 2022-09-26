#!/usr/bin/env python3

# Compute histogram for the three topics in the simple data LDA
# model.

import sys
import re
import numpy as np
import matplotlib.pyplot as plt
import json

# Remove first line of output (accept rate)
sys.stdin.readline()

# Samples
theta1 = []
theta2 = []
theta3 = []

for line in sys.stdin:
    line = re.sub(' +', ' ', line).rsplit(' ', 1)[0].split()
    theta1.append(float(line[0]))
    theta1.append(float(line[2]))
    theta1.append(float(line[4]))

# Burn some samples
burn = 0.1
burn = int(burn*len(theta1))
del theta1[:burn]
del theta2[:burn]
del theta3[:burn]

# Compute histogram representation and print to stdout
counts1, bins1 = np.histogram(theta1, bins=50)
counts2, bins2 = np.histogram(theta2, bins=50)
counts3, bins3 = np.histogram(theta3, bins=50)
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
