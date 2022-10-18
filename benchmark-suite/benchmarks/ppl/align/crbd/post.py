#!/usr/bin/env python3

# Compute histogram for the three topics in the simple data LDA
# model.

import statistics
import sys
import re
import numpy as np
import json

# import matplotlib.pyplot as plt

# Remove first line of output (accept rate)
sys.stdin.readline()

# Samples
lam = []

for line in sys.stdin:
    line = re.sub(' +', ' ', line).rsplit(' ', 1)[0].split()
    lam.append(float(line[0]))

# Burn some samples
burn = 0.1
burn = int(burn*len(lam))
del lam[:burn]

# Compute histogram representation and print to stdout
counts, bins = np.histogram(lam, bins=50, range=(0,1))

data=json.dumps({
    "mean": statistics.mean(lam),
    "counts": counts.tolist(), "bins": bins.tolist()
}, separators=(',', ':'))
print(data)

# Example of how to load and use the JSON-serialized data above:
# data = json.loads(data)
# print(data["mean"])
# plt.hist(data["bins"][:-1], data["bins"], weights=data["counts"])
# plt.show()
