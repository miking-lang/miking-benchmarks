/*
 * Delayed version of CRBD model.
 * Both parameters are delayed.
 *
 * This model traverses the tree with a pre-computed DFS path (defined by the next 
 * pointer in the tree) that corresponds to the recursive calls in the original model. 
 */

#include <stdio.h>
#include <string>
#include <fstream>
#include <math.h>

#include "inference/smc/smc.cuh"
#include "../tree-utils/tree_utils.cuh"
#include "utils/math.cuh"

typedef Lari_tree_t tree_t;
const floating_t rhoConst = 0.8410596026490066;
 
const floating_t kMu = 1;
const floating_t thetaMu = 0.5;
const floating_t kLambda = 1;
const floating_t thetaLambda = 1.0;

#include "crbd_delayed.cuh"

MAIN(    
    ADD_BBLOCK(simCRBD)
    ADD_BBLOCK(simTree)
    //ADD_BBLOCK(survivorshipBias) needs to be implemented
    //ADD_BBLOCK(sampleFinalLambda)
    
    //SMC(saveResults)
    SMC(NULL)
)
  
