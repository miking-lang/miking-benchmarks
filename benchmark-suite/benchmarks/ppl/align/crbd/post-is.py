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
lam = []
weights = []

for line in sys.stdin:
    line = re.sub(' +', ' ', line).rsplit(' ', 1)
    sample = line[0].split()
    lam.append(float(sample[0]))
    weight = line[1]
    weights.append(float(weight))

m = max(weights)
weights = [math.exp(w - m) for w in weights]

# Compute histogram representation and print to stdout
counts, bins = np.histogram(lam, bins=50, range=(0,1), weights=weights)

# Compute sample mean
wsum = sum(weights)
mean = sum([ w*l for w, l in zip([w / wsum for w in weights],lam)])

data=json.dumps({
    "mean": mean,
    "counts": counts.tolist(), "bins": bins.tolist()
}, separators=(',', ':'))
print(data)

# Example of how to load and use the JSON-serialized data above:
# data = json.loads(data)
# plt.hist(data["bins1"][:-1], data["bins1"], weights=data["counts1"])
# plt.show()
