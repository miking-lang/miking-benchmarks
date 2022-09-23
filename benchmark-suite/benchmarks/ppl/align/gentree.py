#!/usr/bin/env python3

# Script to generate synthetic phylogenetic trees in CorePPL format (used in crbd/ and clads/).
# Usage: ./gentree.py <lambda> <mu> <tree_age>

import sys
from numpy.random import default_rng
from scipy.stats import bernoulli

rng = default_rng()

lam = float(sys.argv[1])
mu = float(sys.argv[2])
age = float(sys.argv[3])

def crbd(age):
    # Draw next event from expontential. If age is less than 0, return just a leaf at 0.
    delta = rng.exponential(1/(lam + mu))
    delta_age = age - delta
    if delta_age < 0:
        return {'type': 'leaf', 'age': 0.0}

    # Check if it's a birth or death event
    birth = bernoulli.rvs(lam / (lam + mu))

    if birth:
        # Birth: simulate side branches. If exactly one dies out, extend the current branch to first split in the one that survived
        left = crbd(delta_age)
        right = crbd(delta_age)
        if left is not None and right is not None:
            return {'type': 'node', 'left': left, 'right': right, 'age': delta_age}
        elif left is not None:
            return left
        elif right is not None:
            return right
        else:
            return None

    else:
        return None

left = None
right = None
while left is None: left = crbd(age)
while right is None: right = crbd(age)

tree = {'type': 'node', 'left': left, 'right': right, 'age': age}

def float_to_string(f): "{:.2f}".format(f)

def pr(tree):
    if tree['type'] == 'node':
        return f'Node {{left = {pr(tree["left"])}, right = {pr(tree["right"])}, age = {str(tree["age"])}}}'
    else:
        return f'Leaf {{age = {str(tree["age"])}}}'

print(f'''\
-- Synthetic generated tree with true parameters lambda = {str(lam)} and mu = {str(mu)}

include "tree.mc"

let rho = 1.0

let tree = {pr(tree)}
''')
