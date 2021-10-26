/**
 Example using CRBD 
 */

#include <stdio.h>
#include <string>
#include <fstream>

#include "inference/smc/smc.cuh"
#include "phyrppl/trees/tree_utils.cuh"
#include "phyrppl/trees/birds.cuh"
#include "utils/math.cuh"

typedef Alcedinidae_tree_t tree_t;
const floating_t rhoConst = 0.5684210526315789;

// typedef primate_tree_t tree_t;
// typedef moth_div_tree_t tree_t;
// typedef Accipitridae_tree_t tree_t;

const floating_t k = 1.0;
const floating_t theta = 1.0;
const floating_t kMu = 1.0;
const floating_t thetaMu = 0.5;

#include "phyrppl/models/CRBD.cuh"

MAIN(
     FIRST_BBLOCK(simCRBD)
     //SMC(saveResults)
     SMC(NULL)
)
