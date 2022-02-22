/*
 *  models/Yap_Dengue.cu
 *
 *  Copyright (C) 2021 Viktor Senderov and Paper Authors
 *
 *  The Yap-Dengue epidemilogical model.  Input hardcoded for now.
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

/* Test182_observations_t
   Type wrapper of the test observations that we are using for the paper. */
struct Test183_observations_t {
  static const int NUM_OBSERVATIONS = 183;
  const int cases[NUM_OBSERVATIONS] = {1, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 2, 0, 0, 1, 0, 0, 2, 1, 4, 2, 3, 2, 2, 4, 1, 3, 3, 4, 3, 3, 9, 1, 1, 7, 5, 4, 1, 2, 4, 7, 3, 6, 6, 4, 8, 6, 7, 2, 6, 7, 5, 7, 9, 10, 14, 9, 4, 5, 7, 10, 11, 17, 6, 13, 13, 14, 13, 12, 12, 15, 16, 12, 14, 11, 17, 10, 10, 16, 12, 17, 29, 21, 21, 25, 17, 12, 18, 11, 12, 10, 18, 8, 14, 10, 15, 16, 8, 7, 5, 7, 5, 5, 6, 11, 10, 5, 4, 9, 6, 1, 6, 3, 6, 4, 3, 5, 1, 8, 2, 9, 4, 5, 4, 3, 3, 4, 4, 3, 3, 4, 5, 2, 5, 4, 2, 6, 4, 2, 0, 4, 2, 1, 1, 1, 2, 3, 3, 3, 0, 3, 2, 1, 0, 1, 0, 0, 1, 2, 2, 1, 0, 1, 1, 1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 0};
};

typedef Test183_observations_t y_obs_t;

BBLOCK_DATA(y_obs, y_obs_t, 1)

typedef struct {
  int dS[y_obs->NUM_OBSERVATIONS]; // Newly succeptible
  int dE[y_obs->NUM_OBSERVATIONS]; // Newly exposed (incubating)
  int dI[y_obs->NUM_OBSERVATIONS]; // Newly infectious
  int dR[y_obs->NUM_OBSERVATIONS]; // Newly recovered

  int s[y_obs->NUM_OBSERVATIONS]; //  succeptible
  int e[y_obs->NUM_OBSERVATIONS]; //  exposed (incubating)
  int i[y_obs->NUM_OBSERVATIONS]; //  infectious
  int r[y_obs->NUM_OBSERVATIONS]; //  recovered

  floating_t nu; // birth probability ν
  floating_t mu; // survival probability μ
  floating_t lambda; // exposure probability λ
  floating_t delta; // infection probability δ
  floating_t gamma; // recovery probability γ
} SEIRComponent;


/* SEIRTransfer

 * - t: Step number.
 * - τ: Number of trials that may result in exposure.
 *
 * `τ` is computed externally according to the interaction between two
 * populations, then `transfer()` called to update the state of the
 * population.
 */
BBLOCK_HELPER(SEIRTransfer, {
    /* total population */
    int n = pop->s[t - 1] + pop->e[t - 1] + pop->i[t - 1] + pop->r[t - 1];

    /* transfers */
    pop->dE[t] = SAMPLE(binomial, pop->lambda, tau);
    pop->dI[t] = SAMPLE(binomial, pop->delta, pop->e[t - 1]);
    pop->dR[t] = SAMPLE(binomial, pop->gamma, pop->i[t - 1]);

    pop->s[t] = pop->s[t - 1] - pop->dE[t];
    pop->e[t] = pop->e[t - 1] + pop->dE[t] - pop->dI[t];
    pop->i[t] = pop->i[t - 1] + pop->dI[t] - pop->dR[t];
    pop->r[t] = pop->r[t - 1] + pop->dR[t];

    /* survival; we assume that if the survival rate is set to one, what is
     * meant is "all survive" regardless of the population size, and so do
     * not evaluate these, ensuring we don't get -inf weights for mismatching
     * numbers of trials (population sizes) */
    if (pop->mu != 1.0) {
      pop->s[t] = SAMPLE(binomial, pop->mu, pop->s[t]);
      pop->e[t] = SAMPLE(binomial, pop->mu, pop->e[t]);
      pop->i[t] = SAMPLE(binomial, pop->mu, pop->i[t]);
      pop->r[t] = SAMPLE(binomial, pop->mu, pop->r[t]);
    }

    /* births */
    if (pop->nu != 0.0) {
      pop->dS[t] = SAMPLE(binomial, pop->nu, n);
      pop->s[t] = pop->s[t] + pop->dS[t];
    }

  }, void, SEIRComponent* pop, int t, int tau);

typedef short obsIdx_t;

struct progState_t {
  obsIdx_t t;

  SEIRComponent m; // Mosquito
  SEIRComponent h; // Human

  floating_t rho; // Probability of a human case being observed.
  int z = 0; // Latent aggregate number of cases since last observation.
};

INIT_MODEL(progState_t)


/*
 * simObservation
 */
BBLOCK(simObservation,
{
  int t = PSTATE.t;
  y_obs_t* y = DATA_POINTER(y_obs);

  if (PSTATE.t < y->NUM_OBSERVATIONS - 1) PSTATE.t = ++t;
  else {
    NEXT = NULL;
    return;
  }
  assert(t>=1);
  int n = PSTATE.h.s[t - 1] + PSTATE.h.e[t - 1] + PSTATE.h.i[t - 1] + PSTATE.h.r[t - 1];

  /* transition of human population */
  int tau_h = SAMPLE(binomial, 1.0 - exp(-PSTATE.m.i[t - 1]/ (floating_t) n), PSTATE.h.s[t - 1]);
  BBLOCK_CALL(SEIRTransfer, &PSTATE.h, t, tau_h);

  /* transition of mosquito population */
  int tau_m = SAMPLE(binomial, 1.0 - exp(-PSTATE.h.i[t - 1]/(floating_t) n), PSTATE.m.s[t - 1]);
  BBLOCK_CALL(SEIRTransfer, &PSTATE.m, t, tau_m);
  PSTATE.z = PSTATE.z + PSTATE.h.dI[t];

  if (y->cases[t] != -1) {
    OBSERVE(binomial, PSTATE.rho, PSTATE.z, y->cases[t]);
    PSTATE.z = 0;
  }
 })


/*
 * simYapDengue
 */
BBLOCK(simYapDengue,
{
  int n = 7370;
  int t = PSTATE.t;

  PSTATE.h.i[t] = SAMPLE(poisson, 5.0);
  PSTATE.h.i[t] = PSTATE.h.i[t] + 1;
  PSTATE.h.e[t] = SAMPLE(poisson, 5.0);

  PSTATE.h.r[t] =   floor(SAMPLE(uniform, 0, 1 + n - PSTATE.h.i[t] - PSTATE.h.e[t]));
  PSTATE.h.s[t] = n - PSTATE.h.e[t] - PSTATE.h.i[t] - PSTATE.h.r[t];

  PSTATE.h.dS[t] = 0;
  PSTATE.h.dE[t] = PSTATE.h.e[t];
  PSTATE.h.dI[t] = PSTATE.h.i[t];
  PSTATE.h.dR[t] = 0;

  floating_t u = SAMPLE(uniform, -1.0, 2.0);
  PSTATE.m.s[t] = floor(n*pow(10.0, u));
  PSTATE.m.e[t] = 0;
  PSTATE.m.i[t] = 0;
  PSTATE.m.r[t] = 0;

  PSTATE.m.dS[t] = 0;
  PSTATE.m.dE[t] = 0;
  PSTATE.m.dI[t] = 0;
  PSTATE.m.dR[t] = 0;

  /* observation */
  y_obs_t* y = DATA_POINTER(y_obs);
  PSTATE.z = PSTATE.z + PSTATE.h.dI[t];
  if (y->cases[t] != -1) {
    OBSERVE(binomial, PSTATE.rho, PSTATE.z, y->cases[t]);
    PSTATE.z = 0;
  }

  NEXT = simObservation;

 })


BBLOCK(initialization, {
    PSTATE.h.nu = 0.0;
    PSTATE.h.mu = 1.0;
    PSTATE.h.lambda = SAMPLE(beta, 1.0, 1.0);
    PSTATE.h.delta = SAMPLE(beta, 1.0 + 2.0/4.4, 3.0 - 2.0/4.4);
    PSTATE.h.gamma = SAMPLE(beta, 1.0 + 2.0/4.5, 3.0 - 2.0/4.5);

    PSTATE.m.nu = 1.0/7.0;
    PSTATE.m.mu = 6.0/7.0;
    PSTATE.m.lambda = SAMPLE(beta, 1.0, 1.0);
    PSTATE.m.delta = SAMPLE(beta,1.0 + 2.0/6.5, 3.0 - 2.0/6.5);
    PSTATE.m.gamma = 0.0;

    PSTATE.rho =  SAMPLE(beta, 1.0, 1.0);

    PSTATE.z = 0;
    PSTATE.t = 0;

    NEXT = simYapDengue;
    BBLOCK_CALL(NEXT, NULL);
})


MAIN({
    FIRST_BBLOCK(initialization);
    SMC(NULL)
})
