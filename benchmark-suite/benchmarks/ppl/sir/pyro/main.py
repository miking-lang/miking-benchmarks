#!/usr/bin/env python

import sys
import getopt
from infer.smcfilter import SMCFilter, SMCFailed
#from pyro.infer import SMCFilter
from models.sir import SIR, SIRGuide


N = 131072

options, arguments = getopt.getopt(sys.argv[1:], '', ["nparticles="])
for option, value in options:
    if option == '--nparticles':
        N = int(value)

λ = 10.0
s0 = 760
i0 = 3
r0 = 0
i_obs = [
  6,
  25,
  73,
  222,
  294,
  258,
  237,
  191,
  125,
  69,
  27,
  11,
  4
]

try:
    smc = SMCFilter(model=SIR(), guide=SIRGuide(), num_particles=N, max_plate_nesting=0, ess_threshold=1.0)
    smc.init(λ, s0, i0, r0)
    for idx, i in enumerate(i_obs):
        smc.step(idx+1, i)
    print('%f' % smc.get_marginal_log_likelihood())
except SMCFailed:
    print('NaN')
