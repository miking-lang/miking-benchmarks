#include <iostream>
#include <cstring>
#include <cassert>
#include <string>
#include <fstream>
#include <algorithm>
#include <random>

#include "inference/smc/smc.cuh"
#include "trees/tree_utils.cuh"
#include "utils/math.cuh"
#include "utils/stack.cuh"
#include "dists/delayed.cuh"
#include "trees/cetaceans.cuh"
#include "trees/default_trees.cuh"

#define CLADS false              // Cladogenetic changes
#define ANADS true               // Anagenetic changes
#define EXTINCTION 2            // 2 - constant turnover, 1 - const, 0 - no exticntion

#define RARE_SHIFT false          // RARE_DS model TODO
#define RESAMPLE_RATES false      // TODO resample turnover and anagenesis rate at rate shifts

/* Do not tune unless you know what you're doing! */
#define GUARD true
#define NICOLAS false
#define MAX_FACTOR 1e5 
#define MIN_FACTOR 1e-5
#define M 20              // Number of subsamples to draw
#define DEBUG false
unsigned int depth;


//typedef bisse32_tree_t tree_t;
typedef cetaceans_87_tree_t tree_t;
BBLOCK_DATA(tree, tree_t, 1)
BBLOCK_DATA_CONST(rho, floating_t, 1.0)

#define NUM_BBLOCKS 4
#include "../models/CombineDS.cuh"

BBLOCK(initialization, {
    // Priors
    PSTATE.lambda_0 = gamma_t(1.0, 1.0);
    PSTATE.mu_0 = gamma_t(1.0, 0.5);
    PSTATE.nu_0 = gamma_t(1.0, 2.0);
    PSTATE.alpha_sigma = normalInverseGamma_t(0, 1.0, 1.0, 0.2);
    PSTATE.alpha_sigma_nu = normalInverseGamma_t(0, 1.0, 1.0, 0.2);
    
    //PSTATE.epsilon = 0.5;
    //PSTATE.ypsilon = 1;
    
    // // Immediate sampling
    // floating_t lambda0 = SAMPLE(gamma, lambda_0.k, lambda_0.theta);
    // floating_t sigma = sqrt( 1/ SAMPLE(gamma, a, 1/b));
    // floating_t alpha = exp( SAMPLE(normal, m0, sigma));
    
    PC++;
})

MAIN({
    ADD_BBLOCK(initialization);
    ADD_BBLOCK(simCombineDS);
    ADD_BBLOCK(simTree);
    //ADD_BBLOCK(conditionOnDetection);
    //ADD_BBLOCK(sampleFinalLambda);
    //SMC(saveResults);
    SMC(NULL)
})
