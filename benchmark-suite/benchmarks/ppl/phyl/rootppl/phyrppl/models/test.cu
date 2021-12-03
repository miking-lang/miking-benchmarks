/* 
 *  models/CombineDS.cuh
 *
 *  Copyright (C) 2020-2021 Viktor Senderov, Joey Öhman, David Broman
 * 
 *
 *  CombineDS diversification model supports conditionally simulates
 *  several different types of evolution:
 *
 *    - cladogenetic (ClaDS-like) small changes in diversification
 *      rates, ClaDS versions 0-2.
 *	      
 *    - anagenetic small changes (happening on a single lineage)
 *
 *    - rare large shits (both anagenetic and cladogenetic)
 *
 *    - uncoupling of the turnover rate at the rare large shifts for
 *      ClaDS2
 *
 *
 *  This file needs to be included by a .cu file, containing the MAIN
 *  macro, needed global parameters, needed tuning parameters, and 
 *  the tree structure as a datatype.
 * 
 *  Needed global parameters:
 * 
 *    const floating_t k = 1;            // prior Γ-shape for λ
 *    const floating_t theta = 1;        // prior Γ-scale for λ
 *
 *    const floating_t kNu = 1;          // prior Γ-shape for ν
 *    const floating_t thetaNu = 0.5;    // prior Γ-shape for ν
 *
 *    const floating_t a_epsilon = 1;    // prior β-shape 1 for p_ε
 *    const floating_t b_epsilon = 100;  // prior β-shape 2 for p_ε
 *
 *    const floating_t m0 = 0;   // Hyper-param of prior for α and σ
 *    const floating_t v = 1;    // Hyper-param of prior for α and σ
 *    const floating_t a = 1.0;  // Hyper-param of prior for α and σ
 *    const floating_t b = 0.2;  // Hyper-param of prior for α and σ
 * 
 *  Needed tuning parameters:
 *
 *    #define M 20              // Number of subsamples to draw
 *    #define RARE_SHIFT false  // Activate rare shifts
 *    #define CLADS true        // Cladogenetic changes
 *    #define ANADS true        // Anagenetic changes
 *    #define UNCOUPLE true     // Uncouples turnover rate at rare shifts
 *    #define CLADS1 false      // ClaDS version: 0, 1, or 2, TODO 0
 *
 *  Tree selection, 3 steps:
 *
 *    #include "trees/cetaceans.cuh"       // (1)
 *    typedef cetaceans_87_tree_t tree_t;  // (2)
 *    const floating_t rhoConst = 1.00;    // (3) sampling rate
 *
 *  models/CombineDS.cuh defines the following BBLOCKS that can be included
 *  in the MAIN macro:
 *
 *    - simCombinedDS         (required)
 *
 *    - simTree               (required)
 *
 *    - conditionOnDetection  (optional, corrects for survivorship bias)
 *
 *    - sampleFinalLambda     (optional, samples the global parameters,
 *                             which have been delayed)
 *
 *    - saveResults           (optional callback, needs to be used in 
 *                             conjunction with sampleFinalLambda)
 */

/* Preamble */
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



/* Tunable parameters */
#define CLADS false              // Cladogenetic changes
#define CONST_EXTINCTION false   // Constant extinction rate, if it is false CONSTANT_EXTINCTION
//#define ZERO_EXTINCTION        // TODO 

#define ANADS true               // Anagenetic changes
#define CONST_ANAGENESIS false  // TODO

#define RARE_SHIFT false          // Activate rare shifts - works both on ClaDS and AnaDS
#define UNCOUPLE false            // Uncouples turnover rate at rare shifts
// ?? Do we resample yspislon at rate shifts ??

/* Do not tune unless you know what you're doing! */
#define GUARD true
#define MAX_FACTOR 1e5 
#define MIN_FACTOR 1e-5
#define M 20              // Number of subsamples to draw
#define DEBUG false
#define DEBUG1 false
#define DEBUG2 false
unsigned int depth;

/* Tree selection */
//typedef cetaceans_87_tree_t tree_t;
typedef bisse32_tree_t tree_t;
const floating_t rhoConst = 1.0;

/* Priors for diversification parameters λ, μ, ν*/
const floating_t k = 1.0;
const floating_t theta = 1.0;
const floating_t epsilon = 0.5;   // initial extinction rate
const floating_t ypsilon = 0.5;   // initial anagenesis rate

/* Rare shift frequency */
const floating_t a_epsilon = 1;
const floating_t b_epsilon = 100;

/* Concept paper priors */
const floating_t m0 = 0;
const floating_t v = 1;
const floating_t a = 1.0;
const floating_t b = 0.002;

/* New, small shift priors */
// const floating_t m0 = 0;
// const floating_t v = 1;
// const floating_t a = 1.0;
//const floating_t b = 0.2;



/////////////////////////////////////////////////////////////////////////////



BBLOCK_DATA(tree, tree_t, 1)
BBLOCK_DATA_CONST(rho, floating_t, rhoConst)
typedef short treeIdx_t;

/* Program state */
struct progState_t {
  floating_t factors[(tree->NUM_NODES)] = {1.0}; // first is 1, all other 0 for now
  // TODO
  // Technically we don't need a factor for the root (it is assumed to be 1)
  // But for now we are going to waste one posistion for easier debugging.

  floating_t turnover_rates[(tree->NUM_NODES)]; // used to multiply the scale of μ

  bool cladsShifts[(tree->NUM_NODES)] = {0}; // initalize with 0 
  bool anadsShifts[(tree->NUM_NODES)] = {0};
  
  // Distributions, use underscores to denote distributions
  gamma_t lambda_0;
  gamma_t mu_0;
  gamma_t nu;
  normalInverseGamma_t alpha_sigma;
  beta_t ab;
  
  // Final Values/ Hyperparameters
  // TODO do we need all?
  floating_t lambda0;
  floating_t mu0;
  //  floating_t nu; // name clash
  floating_t alpha;
  floating_t sigma;
  floating_t epsilon;  // initial turn-over rate
  floating_t pEpsilon; // probability of large shift
  treeIdx_t treeIdx;
  int nshifts_clads;
  int nshifts_anads;
};


#define NUM_BBLOCKS 1

INIT_MODEL(progState_t, NUM_BBLOCKS)


/*
 * simCombineDS - required BBLOCK
 */
BBLOCK(simCombineDS,
{

  // Set up tree traversal
  tree_t* treeP = DATA_POINTER(tree);
  PSTATE.treeIdx = treeP->idxLeft[ROOT_IDX];
  
  // Draw initial rates, or delayed declare them

  gamma_t lambda_0(k, theta);
  gamma_t mu_0(k, theta);
  gamma_t nu(k, theta);
  beta_t ab(a_epsilon, b_epsilon);
  normalInverseGamma_t alpha_sigma(m0, v, a, b);

  PSTATE.epsilon = epsilon;  PSTATE.lambda_0 = lambda_0;
  PSTATE.mu_0 = mu_0;
  PSTATE.nu = nu;
  PSTATE.ab = ab;
  PSTATE.alpha_sigma = alpha_sigma;
  
  floating_t f1 = SAMPLE(sample_NormalInverseGammaNormal, PSTATE.alpha_sigma);


  floating_t a = SAMPLE(

  printf("%f %f\n", f1, exp(f1));
  // Advance to next BBLOCK
  PC++;
   
})



MAIN({
    ADD_BBLOCK(simCombineDS);
    SMC(NULL)
})
