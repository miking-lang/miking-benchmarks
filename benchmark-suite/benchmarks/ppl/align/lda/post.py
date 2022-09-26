#!/usr/bin/env python3

# Script that prints the output from the experiments as a list of samples and
# their counts on stdout.

import sys
import re

def read_sample(s):
  return re.sub(' +', ' ', s).rsplit(' ', 1)[0]

# Remove first line of output (accept rate)
sys.stdin.readline()

# First sample
prev_sample = read_sample(sys.stdin.readline())

count = 1
samples = []
counts = []

# Middle samples
for line in sys.stdin:
    sample = read_sample(line)
    if prev_sample == sample:
        count += 1
    else:
        samples.append(prev_sample)
        counts.append(count)
        count = 1
        prev_sample = sample

# Last sample
samples.append(prev_sample)
counts.append(count)

for i, x in enumerate(samples):
    print(str(counts[i]) + " " + str(x))
