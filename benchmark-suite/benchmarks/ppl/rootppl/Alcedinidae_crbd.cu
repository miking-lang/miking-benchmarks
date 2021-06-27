/**
 Example using CRBD 
 */

#include <stdio.h>
#include <string>
#include <fstream>

#include "inference/smc/smc.cuh"
#include "phyrppl/tree-utils/tree_utils.cuh"
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

#include "phyrppl/models/crbd.cuh"

MAIN(
    ADD_BBLOCK(simCRBD)
    ADD_BBLOCK(simTree)
    //ADD_BBLOCK(survivorshipBias)
    
    //SMC(saveResults)
    SMC(NULL)
)
