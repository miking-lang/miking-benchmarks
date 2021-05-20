import sys
import getopt
from infer.smcfilter import SMCFilter
#from pyro.infer import SMCFilter
from utils.phyjson import read_tree
from models.crbd import CRBD, CRBDGuide


tree_path = None
ρ = 1.0
N = 1000

options, arguments = getopt.getopt(sys.argv[1:], '', ["tree=", "rho=", "nparticles="])
for option, value in options:
    if option == '--tree':
        tree_path = value
    if option == '--rho':
        ρ = float(value)
    if option == '--nparticles':
        N = int(value)

smc = SMCFilter(model=CRBD(), guide=CRBDGuide(), num_particles=N, max_plate_nesting=0)
tree = read_tree(tree_path)
smc.init((len(tree) + 1) // 2)
for branch in tree:
    smc.step('branch', branch, ρ)
smc.step('bias_correction', tree[0]['t_beg'], ρ)
print('%f' % smc.get_marginal_log_likelihood())
