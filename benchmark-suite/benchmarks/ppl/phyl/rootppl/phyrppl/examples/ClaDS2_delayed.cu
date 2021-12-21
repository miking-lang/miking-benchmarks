#include <iostream>
#include <cstring>
#include <cassert>
#include <string>
#include <fstream>
#include <algorithm>
#include <random>

#include "inference/smc/smc.cuh"
#include "trees/tree_utils.cuh"
#include "trees/default_trees.cuh"
#include "trees/cetaceans.cuh"
#include "utils/math.cuh"
#include "utils/stack.cuh"
#include "dists/delayed.cuh"
 
/** Tree selection */
//typedef Lari_tree_t tree_t;
//const floating_t rho = 0.8410596026490066;
//typedef bisse32_tree_t tree_t;
typedef cetaceans_87_tree_t tree_t;
const floating_t rho = 1.0;
const int M = 10;

/** Global parameters*/
const floating_t k = 1;
const floating_t theta = 1;
const floating_t kMu = 1;
const floating_t thetaMu = 0.5;

const floating_t m0 = 0;
const floating_t v = 1;
const floating_t a = 1.0;
const floating_t b = 0.2;

std::string analysisName = "ClaDS2_delayed";


#include "models/ClaDS2_delayed.cuh"

MAIN({
    FIRST_BBLOCK(simClaDS2);
    SMC(saveResults);
    //SMC(NULL)
})
 
