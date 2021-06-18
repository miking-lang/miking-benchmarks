/**
 Example using CRBD 
 */

#include <stdio.h>
#include <string>
#include <fstream>

#include "inference/smc/smc.cuh"
#include "tree-utils/tree_utils.cuh"
#include "utils/math.cuh"

typedef bisse32_tree_t tree_t;
const floating_t rhoConst = 1.0;

const floating_t k = 1.0;
const floating_t theta = 1.0;
const floating_t kMu = 1.0;
const floating_t thetaMu = 0.5;

#include "models/crbd.cuh"

MAIN(
    ADD_BBLOCK(simCRBD)
    ADD_BBLOCK(simTree)
    //ADD_BBLOCK(survivorshipBias)
    //SMC(saveResults)
    SMC(NULL)
) 
