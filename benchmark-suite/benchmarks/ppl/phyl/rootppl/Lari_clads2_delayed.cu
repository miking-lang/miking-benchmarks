/*
 * Delayed version of Clads2 model.
 * Both parameters are delayed.
 *
 */

#include <iostream>
#include <cstring>
#include <cassert>
#include <string>
#include <fstream>
#include <algorithm>
#include <random>

#include "inference/smc/smc.cuh"
#include "utils/math.cuh"
#include "utils/stack.cuh"
#include "dists/delayed.cuh"

#include "phyrppl/trees/tree_utils.cuh"
#include "phyrppl/trees/birds.cuh"

typedef Lari_tree_t tree_t;
const floating_t rho = 0.8410596026490066;
  
const floating_t k = 1;
const floating_t theta = 1;
const floating_t kMu = 1;
const floating_t thetaMu = 0.5;

const floating_t m0 = 0;
const floating_t v = 1;
const floating_t a = 1.0;
const floating_t b = 0.2;

std::string analysisName = "exp-03";
const int M = 25; // subsample size

#define NUM_BBLOCKS 3

#include "phyrppl/models/ClaDS2_delayed.cuh"

MAIN({
    FIRST_BBLOCK(simClaDS2)
    SMC(saveResults);
    //SMC(NULL)
})
