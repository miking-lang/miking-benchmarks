#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include "inference/smc/smc.cuh"
#include <stdint.h>
#include <stdio.h>
typedef struct Tree Tree;
typedef struct Rec {double age; Tree (*left); Tree (*right);} Rec;
typedef struct Rec1 {double age;} Rec1;
enum constrs {Node, Leaf};
typedef struct Tree {enum constrs constr; union {Rec (*Node); Rec1 Leaf;};} Tree;
INIT_MODEL_STACK()
struct GLOBAL {double ret; double lambda; double mu;};
struct STACK_init {pplFunc_t ra; double (*retValLoc); Rec (*root);};
struct STACK_walk {pplFunc_t ra; double nodeAge; Rec (*n); double rho; double inf; double lambda; double mu; Tree (*node); double parentAge;};
BBLOCK_DECLARE(start);
BBLOCK_DECLARE(end);
int64_t countLeaves(Tree (*));
BBLOCK_HELPER_DECLARE(STOCH_countLeaves, int64_t, Tree (*));
double getAge(Tree (*));
BBLOCK_HELPER_DECLARE(STOCH_getAge, double, Tree (*));
double externalLog(double);
BBLOCK_HELPER_DECLARE(STOCH_externalLog, double, double);
double log1(double);
BBLOCK_HELPER_DECLARE(STOCH_log, double, double);
double work(double, int64_t);
BBLOCK_HELPER_DECLARE(STOCH_work, double, double, int64_t);
double logFactorial(int64_t);
BBLOCK_HELPER_DECLARE(STOCH_logFactorial, double, int64_t);
BBLOCK_HELPER_DECLARE(survives, char, double, double, double, double);
BBLOCK_HELPER_DECLARE(simHiddenSpeciation, void, double, double, double, double, double, double);
BBLOCK_DECLARE(bblock);
BBLOCK_DECLARE(bblock1);
BBLOCK_DECLARE(bblock2);
BBLOCK_DECLARE(walk);
BBLOCK_DECLARE(bblock3);
BBLOCK_DECLARE(bblock4);
BBLOCK_DECLARE(init);
BBLOCK(start, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  ((PSTATE.stackPtr) = (sizeof(struct GLOBAL)));
  struct STACK_init (*callsf) = (( struct STACK_init (*) ) ((PSTATE.stack) + (( uintptr_t ) (PSTATE.stackPtr))));
  ((callsf->ra) = end);
  ((callsf->retValLoc) = (( double (*) ) ((( char (*) ) (&(global->ret))) - (PSTATE.stack))));
  ((PSTATE.stackPtr) = ((PSTATE.stackPtr) + (sizeof(struct STACK_init))));
  BBLOCK_JUMP(init, NULL);
})
BBLOCK(end, {
  (NEXT = NULL);
})
int64_t countLeaves(Tree (*tree)) {
  if (((tree->constr) == Node)) {
    Rec (*r) = (tree->Node);
    Tree (*t);
    Tree (*X) = (r->left);
    (t = X);
    int64_t t1;
    (t1 = countLeaves(t));
    Tree (*t2);
    Tree (*X1) = (r->right);
    (t2 = X1);
    int64_t t3;
    (t3 = countLeaves(t2));
    int64_t t4;
    (t4 = (t1 + t3));
    return t4;
  } else {
    return 1;
  }
}
BBLOCK_HELPER(STOCH_countLeaves, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  if (((tree->constr) == Node)) {
    Rec (*r) = (tree->Node);
    Tree (*t);
    Tree (*X) = (r->left);
    (t = X);
    int64_t t1;
    (t1 = BBLOCK_CALL(STOCH_countLeaves, t));
    Tree (*t2);
    Tree (*X1) = (r->right);
    (t2 = X1);
    int64_t t3;
    (t3 = BBLOCK_CALL(STOCH_countLeaves, t2));
    int64_t t4;
    (t4 = (t1 + t3));
    return t4;
  } else {
    return 1;
  }
}, int64_t, Tree (*tree))
double getAge(Tree (*n1)) {
  if (((n1->constr) == Node)) {
    Rec (*r1) = (n1->Node);
    double X2 = (r1->age);
    return X2;
  } else {
    if (((n1->constr) == Leaf)) {
      Rec1 r2 = (n1->Leaf);
      double X3 = (r2.age);
      return X3;
    } else {
      ;
    }
  }
}
BBLOCK_HELPER(STOCH_getAge, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  if (((n1->constr) == Node)) {
    Rec (*r1) = (n1->Node);
    double X2 = (r1->age);
    return X2;
  } else {
    if (((n1->constr) == Leaf)) {
      Rec1 r2 = (n1->Leaf);
      double X3 = (r2.age);
      return X3;
    } else {
      ;
    }
  }
}, double, Tree (*n1))
BBLOCK_DATA_MANAGED_SINGLE(t5, Rec1)
BBLOCK_DATA_MANAGED(t6, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t7, Rec1)
BBLOCK_DATA_MANAGED(t8, Tree, 1)
BBLOCK_DATA_MANAGED(t9, Rec, 1)
BBLOCK_DATA_MANAGED(t10, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t11, Rec1)
BBLOCK_DATA_MANAGED(t12, Tree, 1)
BBLOCK_DATA_MANAGED(t13, Rec, 1)
BBLOCK_DATA_MANAGED(t14, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t15, Rec1)
BBLOCK_DATA_MANAGED(t16, Tree, 1)
BBLOCK_DATA_MANAGED(t17, Rec, 1)
BBLOCK_DATA_MANAGED(t18, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t19, Rec1)
BBLOCK_DATA_MANAGED(t20, Tree, 1)
BBLOCK_DATA_MANAGED(t21, Rec, 1)
BBLOCK_DATA_MANAGED(t22, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t23, Rec1)
BBLOCK_DATA_MANAGED(t24, Tree, 1)
BBLOCK_DATA_MANAGED(t25, Rec, 1)
BBLOCK_DATA_MANAGED(t26, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t27, Rec1)
BBLOCK_DATA_MANAGED(t28, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t29, Rec1)
BBLOCK_DATA_MANAGED(t30, Tree, 1)
BBLOCK_DATA_MANAGED(t31, Rec, 1)
BBLOCK_DATA_MANAGED(t32, Tree, 1)
BBLOCK_DATA_MANAGED(t33, Rec, 1)
BBLOCK_DATA_MANAGED(t34, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t35, Rec1)
BBLOCK_DATA_MANAGED(t36, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t37, Rec1)
BBLOCK_DATA_MANAGED(t38, Tree, 1)
BBLOCK_DATA_MANAGED(t39, Rec, 1)
BBLOCK_DATA_MANAGED(t40, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t41, Rec1)
BBLOCK_DATA_MANAGED(t42, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t43, Rec1)
BBLOCK_DATA_MANAGED(t44, Tree, 1)
BBLOCK_DATA_MANAGED(t45, Rec, 1)
BBLOCK_DATA_MANAGED(t46, Tree, 1)
BBLOCK_DATA_MANAGED(t47, Rec, 1)
BBLOCK_DATA_MANAGED(t48, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t49, Rec1)
BBLOCK_DATA_MANAGED(t50, Tree, 1)
BBLOCK_DATA_MANAGED(t51, Rec, 1)
BBLOCK_DATA_MANAGED(t52, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t53, Rec1)
BBLOCK_DATA_MANAGED(t54, Tree, 1)
BBLOCK_DATA_MANAGED(t55, Rec, 1)
BBLOCK_DATA_MANAGED(t56, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t57, Rec1)
BBLOCK_DATA_MANAGED(t58, Tree, 1)
BBLOCK_DATA_MANAGED(t59, Rec, 1)
BBLOCK_DATA_MANAGED(t60, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t61, Rec1)
BBLOCK_DATA_MANAGED(t62, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t63, Rec1)
BBLOCK_DATA_MANAGED(t64, Tree, 1)
BBLOCK_DATA_MANAGED(t65, Rec, 1)
BBLOCK_DATA_MANAGED(t66, Tree, 1)
BBLOCK_DATA_MANAGED(t67, Rec, 1)
BBLOCK_DATA_MANAGED(t68, Tree, 1)
BBLOCK_DATA_MANAGED(t69, Rec, 1)
BBLOCK_DATA_MANAGED(t70, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t71, Rec1)
BBLOCK_DATA_MANAGED(t72, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t73, Rec1)
BBLOCK_DATA_MANAGED(t74, Tree, 1)
BBLOCK_DATA_MANAGED(t75, Rec, 1)
BBLOCK_DATA_MANAGED(t76, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t77, Rec1)
BBLOCK_DATA_MANAGED(t78, Tree, 1)
BBLOCK_DATA_MANAGED(t79, Rec, 1)
BBLOCK_DATA_MANAGED(t80, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t81, Rec1)
BBLOCK_DATA_MANAGED(t82, Tree, 1)
BBLOCK_DATA_MANAGED(t83, Rec, 1)
BBLOCK_DATA_MANAGED(t84, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t85, Rec1)
BBLOCK_DATA_MANAGED(t86, Tree, 1)
BBLOCK_DATA_MANAGED(t87, Rec, 1)
BBLOCK_DATA_MANAGED(t88, Tree, 1)
BBLOCK_DATA_MANAGED(t89, Rec, 1)
BBLOCK_DATA_MANAGED(t90, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t91, Rec1)
BBLOCK_DATA_MANAGED(t92, Tree, 1)
BBLOCK_DATA_MANAGED(t93, Rec, 1)
BBLOCK_DATA_MANAGED(t94, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t95, Rec1)
BBLOCK_DATA_MANAGED(t96, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t97, Rec1)
BBLOCK_DATA_MANAGED(t98, Tree, 1)
BBLOCK_DATA_MANAGED(t99, Rec, 1)
BBLOCK_DATA_MANAGED(t100, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t101, Rec1)
BBLOCK_DATA_MANAGED(t102, Tree, 1)
BBLOCK_DATA_MANAGED(t103, Rec, 1)
BBLOCK_DATA_MANAGED(t104, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t105, Rec1)
BBLOCK_DATA_MANAGED(t106, Tree, 1)
BBLOCK_DATA_MANAGED(t107, Rec, 1)
BBLOCK_DATA_MANAGED(t108, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t109, Rec1)
BBLOCK_DATA_MANAGED(t110, Tree, 1)
BBLOCK_DATA_MANAGED(t111, Rec, 1)
BBLOCK_DATA_MANAGED(t112, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t113, Rec1)
BBLOCK_DATA_MANAGED(t114, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t115, Rec1)
BBLOCK_DATA_MANAGED(t116, Tree, 1)
BBLOCK_DATA_MANAGED(t117, Rec, 1)
BBLOCK_DATA_MANAGED(t118, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t119, Rec1)
BBLOCK_DATA_MANAGED(t120, Tree, 1)
BBLOCK_DATA_MANAGED(t121, Rec, 1)
BBLOCK_DATA_MANAGED(t122, Tree, 1)
BBLOCK_DATA_MANAGED(t123, Rec, 1)
BBLOCK_DATA_MANAGED(t124, Tree, 1)
BBLOCK_DATA_MANAGED(t125, Rec, 1)
BBLOCK_DATA_MANAGED(t126, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t127, Rec1)
BBLOCK_DATA_MANAGED(t128, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t129, Rec1)
BBLOCK_DATA_MANAGED(t130, Tree, 1)
BBLOCK_DATA_MANAGED(t131, Rec, 1)
BBLOCK_DATA_MANAGED(t132, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t133, Rec1)
BBLOCK_DATA_MANAGED(t134, Tree, 1)
BBLOCK_DATA_MANAGED(t135, Rec, 1)
BBLOCK_DATA_MANAGED(t136, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t137, Rec1)
BBLOCK_DATA_MANAGED(t138, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t139, Rec1)
BBLOCK_DATA_MANAGED(t140, Tree, 1)
BBLOCK_DATA_MANAGED(t141, Rec, 1)
BBLOCK_DATA_MANAGED(t142, Tree, 1)
BBLOCK_DATA_MANAGED(t143, Rec, 1)
BBLOCK_DATA_MANAGED(t144, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t145, Rec1)
BBLOCK_DATA_MANAGED(t146, Tree, 1)
BBLOCK_DATA_MANAGED(t147, Rec, 1)
BBLOCK_DATA_MANAGED(t148, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t149, Rec1)
BBLOCK_DATA_MANAGED(t150, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t151, Rec1)
BBLOCK_DATA_MANAGED(t152, Tree, 1)
BBLOCK_DATA_MANAGED(t153, Rec, 1)
BBLOCK_DATA_MANAGED(t154, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t155, Rec1)
BBLOCK_DATA_MANAGED(t156, Tree, 1)
BBLOCK_DATA_MANAGED(t157, Rec, 1)
BBLOCK_DATA_MANAGED(t158, Tree, 1)
BBLOCK_DATA_MANAGED(t159, Rec, 1)
BBLOCK_DATA_MANAGED(t160, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t161, Rec1)
BBLOCK_DATA_MANAGED(t162, Tree, 1)
BBLOCK_DATA_MANAGED(t163, Rec, 1)
BBLOCK_DATA_MANAGED(t164, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t165, Rec1)
BBLOCK_DATA_MANAGED(t166, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t167, Rec1)
BBLOCK_DATA_MANAGED(t168, Tree, 1)
BBLOCK_DATA_MANAGED(t169, Rec, 1)
BBLOCK_DATA_MANAGED(t170, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t171, Rec1)
BBLOCK_DATA_MANAGED(t172, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t173, Rec1)
BBLOCK_DATA_MANAGED(t174, Tree, 1)
BBLOCK_DATA_MANAGED(t175, Rec, 1)
BBLOCK_DATA_MANAGED(t176, Tree, 1)
BBLOCK_DATA_MANAGED(t177, Rec, 1)
BBLOCK_DATA_MANAGED(t178, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t179, Rec1)
BBLOCK_DATA_MANAGED(t180, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t181, Rec1)
BBLOCK_DATA_MANAGED(t182, Tree, 1)
BBLOCK_DATA_MANAGED(t183, Rec, 1)
BBLOCK_DATA_MANAGED(t184, Tree, 1)
BBLOCK_DATA_MANAGED(t185, Rec, 1)
BBLOCK_DATA_MANAGED(t186, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t187, Rec1)
BBLOCK_DATA_MANAGED(t188, Tree, 1)
BBLOCK_DATA_MANAGED(t189, Rec, 1)
BBLOCK_DATA_MANAGED(t190, Tree, 1)
BBLOCK_DATA_MANAGED(t191, Rec, 1)
BBLOCK_DATA_MANAGED(t192, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t193, Rec1)
BBLOCK_DATA_MANAGED(t194, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t195, Rec1)
BBLOCK_DATA_MANAGED(t196, Tree, 1)
BBLOCK_DATA_MANAGED(t197, Rec, 1)
BBLOCK_DATA_MANAGED(t198, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t199, Rec1)
BBLOCK_DATA_MANAGED(t200, Tree, 1)
BBLOCK_DATA_MANAGED(t201, Rec, 1)
BBLOCK_DATA_MANAGED(t202, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t203, Rec1)
BBLOCK_DATA_MANAGED(t204, Tree, 1)
BBLOCK_DATA_MANAGED(t205, Rec, 1)
BBLOCK_DATA_MANAGED(t206, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t207, Rec1)
BBLOCK_DATA_MANAGED(t208, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(t209, Rec1)
BBLOCK_DATA_MANAGED(t210, Tree, 1)
BBLOCK_DATA_MANAGED(t211, Rec, 1)
BBLOCK_DATA_MANAGED(t212, Tree, 1)
BBLOCK_DATA_MANAGED(t213, Rec, 1)
BBLOCK_DATA_MANAGED(t214, Tree, 1)
BBLOCK_DATA_MANAGED(t215, Rec, 1)
BBLOCK_DATA_MANAGED(t216, Tree, 1)
BBLOCK_DATA_MANAGED(t217, Rec, 1)
BBLOCK_DATA_MANAGED(tree1, Tree, 1)
BBLOCK_DATA_MANAGED_SINGLE(rho, double)
double externalLog(double a1) {
  return log(a1);
}
BBLOCK_HELPER(STOCH_externalLog, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  return log(a1);
}, double, double a1)
double log1(double x) {
  double t218;
  (t218 = log(x));
  return t218;
}
BBLOCK_HELPER(STOCH_log, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  double t218;
  (t218 = log(x));
  return t218;
}, double, double x)
BBLOCK_DATA_MANAGED_SINGLE(inf, double)
double work(double acc, int64_t n2) {
  char t219;
  (t219 = (n2 > 0));
  if ((t219 == 1)) {
    double t220;
    (t220 = (( double ) n2));
    double t221;
    (t221 = log1(t220));
    double t222;
    (t222 = (t221 + acc));
    int64_t t223;
    (t223 = (n2 - 1));
    double t224;
    (t224 = work(t222, t223));
    return t224;
  } else {
    return acc;
  }
}
BBLOCK_HELPER(STOCH_work, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  char t219;
  (t219 = (n2 > 0));
  if ((t219 == 1)) {
    double t220;
    (t220 = (( double ) n2));
    double t221;
    (t221 = BBLOCK_CALL(STOCH_log, t220));
    double t222;
    (t222 = (t221 + acc));
    int64_t t223;
    (t223 = (n2 - 1));
    double t224;
    (t224 = BBLOCK_CALL(STOCH_work, t222, t223));
    return t224;
  } else {
    return acc;
  }
}, double, double acc, int64_t n2)
double logFactorial(int64_t n3) {
  double t225;
  (t225 = work(0., n3));
  return t225;
}
BBLOCK_HELPER(STOCH_logFactorial, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  double t225;
  (t225 = BBLOCK_CALL(STOCH_work, 0., n3));
  return t225;
}, double, int64_t n3)
BBLOCK_HELPER(survives, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  double t226;
  (t226 = ((global->lambda) + (global->mu)));
  double t227;
  (t227 = (SAMPLE(exponential, t226)));
  double t228;
  (t228 = (tBeg - t227));
  char t229;
  (t229 = (t228 < 0.));
  if ((t229 == 1)) {
    return (SAMPLE(bernoulli, rho));
  } else {
    double t230;
    (t230 = ((global->lambda) + (global->mu)));
    double t231;
    (t231 = ((global->lambda) / t230));
    char t232;
    (t232 = (SAMPLE(bernoulli, t231)));
    if ((t232 == 1)) {
      char t233;
      (t233 = BBLOCK_CALL(survives, rho, (global->lambda), (global->mu), t228));
      if ((t233 == 1)) {
        return 1;
      } else {
        char t234;
        (t234 = BBLOCK_CALL(survives, rho, (global->lambda), (global->mu), t228));
        return t234;
      }
    } else {
      return 0;
    }
  }
}, char, double rho, double lambda, double mu, double tBeg)
BBLOCK_HELPER(simHiddenSpeciation, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  double t235;
  (t235 = (SAMPLE(exponential, (global->lambda))));
  double t236;
  (t236 = (tBeg1 - t235));
  char t237;
  (t237 = (t236 > nodeAge));
  if ((t237 == 1)) {
    char t238;
    (t238 = BBLOCK_CALL(survives, rho, (global->lambda), (global->mu), t236));
    if ((t238 == 1)) {
      double t239;
      (t239 = (-inf));
      (WEIGHT(t239));
    } else {
      double t240;
      (t240 = BBLOCK_CALL(STOCH_log, 2.));
      (WEIGHT(t240));
      BBLOCK_CALL(simHiddenSpeciation, rho, inf, (global->lambda), (global->mu), nodeAge, t236);
    }
  } else {
    ;
  }
}, void, double rho, double inf, double lambda, double mu, double nodeAge, double tBeg1)
BBLOCK(bblock, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_walk (*sf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))))));
  ((PSTATE.stackPtr) = ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))));
  BBLOCK_JUMP((sf->ra), NULL);
})
BBLOCK(bblock1, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_walk (*sf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))))));
  Tree (*t241);
  Tree (*X4) = ((sf->n)->right);
  (t241 = X4);
  struct STACK_walk (*callsf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) (PSTATE.stackPtr))));
  ((callsf->ra) = bblock);
  ((callsf->rho) = (sf->rho));
  ((callsf->inf) = (sf->inf));
  ((callsf->lambda) = (sf->lambda));
  ((callsf->mu) = (sf->mu));
  ((callsf->node) = t241);
  ((callsf->parentAge) = (sf->nodeAge));
  ((PSTATE.stackPtr) = ((PSTATE.stackPtr) + (sizeof(struct STACK_walk))));
  BBLOCK_JUMP(walk, NULL);
})
BBLOCK(bblock2, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_walk (*sf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))))));
  Tree (*t242);
  Tree (*X5) = ((sf->n)->left);
  (t242 = X5);
  struct STACK_walk (*callsf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) (PSTATE.stackPtr))));
  ((callsf->ra) = bblock1);
  ((callsf->rho) = (sf->rho));
  ((callsf->inf) = (sf->inf));
  ((callsf->lambda) = (sf->lambda));
  ((callsf->mu) = (sf->mu));
  ((callsf->node) = t242);
  ((callsf->parentAge) = (sf->nodeAge));
  ((PSTATE.stackPtr) = ((PSTATE.stackPtr) + (sizeof(struct STACK_walk))));
  BBLOCK_JUMP(walk, NULL);
})
BBLOCK(walk, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_walk (*sf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))))));
  ((sf->nodeAge) = BBLOCK_CALL(STOCH_getAge, (sf->node)));
  BBLOCK_CALL(simHiddenSpeciation, (sf->rho), (sf->inf), (sf->lambda), (sf->mu), (sf->nodeAge), (sf->parentAge));
  double t243;
  (t243 = ((sf->parentAge) - (sf->nodeAge)));
  double t244;
  (t244 = ((sf->mu) * t243));
  (OBSERVE(poisson, t244, 0));
  if ((((sf->node)->constr) == Node)) {
    ((sf->n) = ((sf->node)->Node));
    (OBSERVE(exponential, (sf->lambda), 0.));
    (NEXT = bblock2);
  } else {
    if ((((sf->node)->constr) == Leaf)) {
      (OBSERVE(bernoulli, (sf->rho), 1));
      ((PSTATE.stackPtr) = ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))));
      (NEXT = (sf->ra));
    } else {
      ;
      ((PSTATE.stackPtr) = ((PSTATE.stackPtr) - (sizeof(struct STACK_walk))));
      BBLOCK_JUMP((sf->ra), NULL);
    }
  }
})
BBLOCK_DATA_MANAGED_SINGLE(numLeaves, int64_t)
BBLOCK_DATA_MANAGED_SINGLE(t245, double)
BBLOCK_DATA_MANAGED_SINGLE(t246, double)
BBLOCK_DATA_MANAGED_SINGLE(t247, double)
BBLOCK_DATA_MANAGED_SINGLE(t248, double)
BBLOCK_DATA_MANAGED_SINGLE(t249, double)
BBLOCK_DATA_MANAGED_SINGLE(t250, double)
BBLOCK(bblock3, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_init (*sf) = (( struct STACK_init (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_init))))));
  ((*(( double (*) ) ((PSTATE.stack) + (( uintptr_t ) (sf->retValLoc))))) = (global->lambda));
  ((PSTATE.stackPtr) = ((PSTATE.stackPtr) - (sizeof(struct STACK_init))));
  BBLOCK_JUMP((sf->ra), NULL);
})
BBLOCK(bblock4, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_init (*sf) = (( struct STACK_init (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_init))))));
  Tree (*t251);
  Tree (*X6) = ((sf->root)->right);
  (t251 = X6);
  double t252;
  double X7 = ((sf->root)->age);
  (t252 = X7);
  struct STACK_walk (*callsf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) (PSTATE.stackPtr))));
  ((callsf->ra) = bblock3);
  ((callsf->rho) = rho);
  ((callsf->inf) = inf);
  ((callsf->lambda) = (global->lambda));
  ((callsf->mu) = (global->mu));
  ((callsf->node) = t251);
  ((callsf->parentAge) = t252);
  ((PSTATE.stackPtr) = ((PSTATE.stackPtr) + (sizeof(struct STACK_walk))));
  BBLOCK_JUMP(walk, NULL);
})
BBLOCK(init, {
  struct GLOBAL (*global) = (( struct GLOBAL (*) ) (PSTATE.stack));
  struct STACK_init (*sf) = (( struct STACK_init (*) ) ((PSTATE.stack) + (( uintptr_t ) ((PSTATE.stackPtr) - (sizeof(struct STACK_init))))));
  ((global->lambda) = (SAMPLE(gamma, 1., 1.)));
  ((global->mu) = (SAMPLE(gamma, 1., 0.5)));
  (WEIGHT(t250));
  if (((tree1->constr) == Node)) {
    ((sf->root) = (tree1->Node));
    Tree (*t253);
    Tree (*X8) = ((sf->root)->left);
    (t253 = X8);
    double t254;
    double X9 = ((sf->root)->age);
    (t254 = X9);
    struct STACK_walk (*callsf) = (( struct STACK_walk (*) ) ((PSTATE.stack) + (( uintptr_t ) (PSTATE.stackPtr))));
    ((callsf->ra) = bblock4);
    ((callsf->rho) = rho);
    ((callsf->inf) = inf);
    ((callsf->lambda) = (global->lambda));
    ((callsf->mu) = (global->mu));
    ((callsf->node) = t253);
    ((callsf->parentAge) = t254);
    ((PSTATE.stackPtr) = ((PSTATE.stackPtr) + (sizeof(struct STACK_walk))));
    BBLOCK_JUMP(walk, NULL);
  } else {
    ;
    ((PSTATE.stackPtr) = ((PSTATE.stackPtr) - (sizeof(struct STACK_init))));
    BBLOCK_JUMP((sf->ra), NULL);
  }
})
CALLBACK(callback, {
  int i = 0;
  while ((i < N)) {
    struct GLOBAL (*global) = (( struct GLOBAL (*) ) ((PSTATES[i]).stack));
    printf("%f %f\n", (global->ret), (WEIGHTS[i]));
    (i = (i + 1));
  }
})
MAIN({
  ((t5.age) = 0.);
  ((t6->constr) = Leaf);
  ((t6->Leaf) = t5);
  ((t7.age) = 0.);
  ((t8->constr) = Leaf);
  ((t8->Leaf) = t7);
  ((t9->age) = 1.900561313);
  ((t9->left) = t8);
  ((t9->right) = t6);
  ((t10->constr) = Node);
  ((t10->Node) = t9);
  ((t11.age) = 0.);
  ((t12->constr) = Leaf);
  ((t12->Leaf) = t11);
  ((t13->age) = 3.100150132);
  ((t13->left) = t12);
  ((t13->right) = t10);
  ((t14->constr) = Node);
  ((t14->Node) = t13);
  ((t15.age) = 0.);
  ((t16->constr) = Leaf);
  ((t16->Leaf) = t15);
  ((t17->age) = 6.043650727);
  ((t17->left) = t16);
  ((t17->right) = t14);
  ((t18->constr) = Node);
  ((t18->Node) = t17);
  ((t19.age) = 0.);
  ((t20->constr) = Leaf);
  ((t20->Leaf) = t19);
  ((t21->age) = 12.38252513);
  ((t21->left) = t20);
  ((t21->right) = t18);
  ((t22->constr) = Node);
  ((t22->Node) = t21);
  ((t23.age) = 0.);
  ((t24->constr) = Leaf);
  ((t24->Leaf) = t23);
  ((t25->age) = 12.61785812);
  ((t25->left) = t24);
  ((t25->right) = t22);
  ((t26->constr) = Node);
  ((t26->Node) = t25);
  ((t27.age) = 0.);
  ((t28->constr) = Leaf);
  ((t28->Leaf) = t27);
  ((t29.age) = 0.);
  ((t30->constr) = Leaf);
  ((t30->Leaf) = t29);
  ((t31->age) = 11.15685875);
  ((t31->left) = t30);
  ((t31->right) = t28);
  ((t32->constr) = Node);
  ((t32->Node) = t31);
  ((t33->age) = 15.396725736);
  ((t33->left) = t32);
  ((t33->right) = t26);
  ((t34->constr) = Node);
  ((t34->Node) = t33);
  ((t35.age) = 0.);
  ((t36->constr) = Leaf);
  ((t36->Leaf) = t35);
  ((t37.age) = 0.);
  ((t38->constr) = Leaf);
  ((t38->Leaf) = t37);
  ((t39->age) = 1.04896206);
  ((t39->left) = t38);
  ((t39->right) = t36);
  ((t40->constr) = Node);
  ((t40->Node) = t39);
  ((t41.age) = 0.);
  ((t42->constr) = Leaf);
  ((t42->Leaf) = t41);
  ((t43.age) = 0.);
  ((t44->constr) = Leaf);
  ((t44->Leaf) = t43);
  ((t45->age) = 0.9841688636);
  ((t45->left) = t44);
  ((t45->right) = t42);
  ((t46->constr) = Node);
  ((t46->Node) = t45);
  ((t47->age) = 1.7140599232);
  ((t47->left) = t46);
  ((t47->right) = t40);
  ((t48->constr) = Node);
  ((t48->Node) = t47);
  ((t49.age) = 0.);
  ((t50->constr) = Leaf);
  ((t50->Leaf) = t49);
  ((t51->age) = 3.786162534);
  ((t51->left) = t50);
  ((t51->right) = t48);
  ((t52->constr) = Node);
  ((t52->Node) = t51);
  ((t53.age) = 0.);
  ((t54->constr) = Leaf);
  ((t54->Leaf) = t53);
  ((t55->age) = 8.788450495);
  ((t55->left) = t54);
  ((t55->right) = t52);
  ((t56->constr) = Node);
  ((t56->Node) = t55);
  ((t57.age) = 0.);
  ((t58->constr) = Leaf);
  ((t58->Leaf) = t57);
  ((t59->age) = 11.05846217);
  ((t59->left) = t58);
  ((t59->right) = t56);
  ((t60->constr) = Node);
  ((t60->Node) = t59);
  ((t61.age) = 0.);
  ((t62->constr) = Leaf);
  ((t62->Leaf) = t61);
  ((t63.age) = 0.);
  ((t64->constr) = Leaf);
  ((t64->Leaf) = t63);
  ((t65->age) = 8.614086751);
  ((t65->left) = t64);
  ((t65->right) = t62);
  ((t66->constr) = Node);
  ((t66->Node) = t65);
  ((t67->age) = 15.008504768);
  ((t67->left) = t66);
  ((t67->right) = t60);
  ((t68->constr) = Node);
  ((t68->Node) = t67);
  ((t69->age) = 16.828404506);
  ((t69->left) = t68);
  ((t69->right) = t34);
  ((t70->constr) = Node);
  ((t70->Node) = t69);
  ((t71.age) = 0.);
  ((t72->constr) = Leaf);
  ((t72->Leaf) = t71);
  ((t73.age) = 0.);
  ((t74->constr) = Leaf);
  ((t74->Leaf) = t73);
  ((t75->age) = 4.220057646);
  ((t75->left) = t74);
  ((t75->right) = t72);
  ((t76->constr) = Node);
  ((t76->Node) = t75);
  ((t77.age) = 0.);
  ((t78->constr) = Leaf);
  ((t78->Leaf) = t77);
  ((t79->age) = 8.451051062);
  ((t79->left) = t78);
  ((t79->right) = t76);
  ((t80->constr) = Node);
  ((t80->Node) = t79);
  ((t81.age) = 0.);
  ((t82->constr) = Leaf);
  ((t82->Leaf) = t81);
  ((t83->age) = 11.54072627);
  ((t83->left) = t82);
  ((t83->right) = t80);
  ((t84->constr) = Node);
  ((t84->Node) = t83);
  ((t85.age) = 0.);
  ((t86->constr) = Leaf);
  ((t86->Leaf) = t85);
  ((t87->age) = 15.28839572);
  ((t87->left) = t86);
  ((t87->right) = t84);
  ((t88->constr) = Node);
  ((t88->Node) = t87);
  ((t89->age) = 20.368109703);
  ((t89->left) = t88);
  ((t89->right) = t70);
  ((t90->constr) = Node);
  ((t90->Node) = t89);
  ((t91.age) = 0.);
  ((t92->constr) = Leaf);
  ((t92->Leaf) = t91);
  ((t93->age) = 23.74299959);
  ((t93->left) = t92);
  ((t93->right) = t90);
  ((t94->constr) = Node);
  ((t94->Node) = t93);
  ((t95.age) = 0.);
  ((t96->constr) = Leaf);
  ((t96->Leaf) = t95);
  ((t97.age) = 0.);
  ((t98->constr) = Leaf);
  ((t98->Leaf) = t97);
  ((t99->age) = 6.306427821);
  ((t99->left) = t98);
  ((t99->right) = t96);
  ((t100->constr) = Node);
  ((t100->Node) = t99);
  ((t101.age) = 0.);
  ((t102->constr) = Leaf);
  ((t102->Leaf) = t101);
  ((t103->age) = 9.40050129);
  ((t103->left) = t102);
  ((t103->right) = t100);
  ((t104->constr) = Node);
  ((t104->Node) = t103);
  ((t105.age) = 0.);
  ((t106->constr) = Leaf);
  ((t106->Leaf) = t105);
  ((t107->age) = 13.85876825);
  ((t107->left) = t106);
  ((t107->right) = t104);
  ((t108->constr) = Node);
  ((t108->Node) = t107);
  ((t109.age) = 0.);
  ((t110->constr) = Leaf);
  ((t110->Leaf) = t109);
  ((t111->age) = 20.68766993);
  ((t111->left) = t110);
  ((t111->right) = t108);
  ((t112->constr) = Node);
  ((t112->Node) = t111);
  ((t113.age) = 0.);
  ((t114->constr) = Leaf);
  ((t114->Leaf) = t113);
  ((t115.age) = 0.);
  ((t116->constr) = Leaf);
  ((t116->Leaf) = t115);
  ((t117->age) = 4.534421013);
  ((t117->left) = t116);
  ((t117->right) = t114);
  ((t118->constr) = Node);
  ((t118->Node) = t117);
  ((t119.age) = 0.);
  ((t120->constr) = Leaf);
  ((t120->Leaf) = t119);
  ((t121->age) = 12.46869821);
  ((t121->left) = t120);
  ((t121->right) = t118);
  ((t122->constr) = Node);
  ((t122->Node) = t121);
  ((t123->age) = 22.82622451);
  ((t123->left) = t122);
  ((t123->right) = t112);
  ((t124->constr) = Node);
  ((t124->Node) = t123);
  ((t125->age) = 32.145876657);
  ((t125->left) = t124);
  ((t125->right) = t94);
  ((t126->constr) = Node);
  ((t126->Node) = t125);
  ((t127.age) = 0.);
  ((t128->constr) = Leaf);
  ((t128->Leaf) = t127);
  ((t129.age) = 0.);
  ((t130->constr) = Leaf);
  ((t130->Leaf) = t129);
  ((t131->age) = 1.962579854);
  ((t131->left) = t130);
  ((t131->right) = t128);
  ((t132->constr) = Node);
  ((t132->Node) = t131);
  ((t133.age) = 0.);
  ((t134->constr) = Leaf);
  ((t134->Leaf) = t133);
  ((t135->age) = 3.732932004);
  ((t135->left) = t134);
  ((t135->right) = t132);
  ((t136->constr) = Node);
  ((t136->Node) = t135);
  ((t137.age) = 0.);
  ((t138->constr) = Leaf);
  ((t138->Leaf) = t137);
  ((t139.age) = 0.);
  ((t140->constr) = Leaf);
  ((t140->Leaf) = t139);
  ((t141->age) = 0.6302632958);
  ((t141->left) = t140);
  ((t141->right) = t138);
  ((t142->constr) = Node);
  ((t142->Node) = t141);
  ((t143->age) = 5.5933070698);
  ((t143->left) = t142);
  ((t143->right) = t136);
  ((t144->constr) = Node);
  ((t144->Node) = t143);
  ((t145.age) = 0.);
  ((t146->constr) = Leaf);
  ((t146->Leaf) = t145);
  ((t147->age) = 6.096453021);
  ((t147->left) = t146);
  ((t147->right) = t144);
  ((t148->constr) = Node);
  ((t148->Node) = t147);
  ((t149.age) = 0.);
  ((t150->constr) = Leaf);
  ((t150->Leaf) = t149);
  ((t151.age) = 0.);
  ((t152->constr) = Leaf);
  ((t152->Leaf) = t151);
  ((t153->age) = 1.519406055);
  ((t153->left) = t152);
  ((t153->right) = t150);
  ((t154->constr) = Node);
  ((t154->Node) = t153);
  ((t155.age) = 0.);
  ((t156->constr) = Leaf);
  ((t156->Leaf) = t155);
  ((t157->age) = 4.987038163);
  ((t157->left) = t156);
  ((t157->right) = t154);
  ((t158->constr) = Node);
  ((t158->Node) = t157);
  ((t159->age) = 8.265483252);
  ((t159->left) = t158);
  ((t159->right) = t148);
  ((t160->constr) = Node);
  ((t160->Node) = t159);
  ((t161.age) = 0.);
  ((t162->constr) = Leaf);
  ((t162->Leaf) = t161);
  ((t163->age) = 10.86835485);
  ((t163->left) = t162);
  ((t163->right) = t160);
  ((t164->constr) = Node);
  ((t164->Node) = t163);
  ((t165.age) = 0.);
  ((t166->constr) = Leaf);
  ((t166->Leaf) = t165);
  ((t167.age) = 0.);
  ((t168->constr) = Leaf);
  ((t168->Leaf) = t167);
  ((t169->age) = 5.054547857);
  ((t169->left) = t168);
  ((t169->right) = t166);
  ((t170->constr) = Node);
  ((t170->Node) = t169);
  ((t171.age) = 0.);
  ((t172->constr) = Leaf);
  ((t172->Leaf) = t171);
  ((t173.age) = 0.);
  ((t174->constr) = Leaf);
  ((t174->Leaf) = t173);
  ((t175->age) = 3.151799953);
  ((t175->left) = t174);
  ((t175->right) = t172);
  ((t176->constr) = Node);
  ((t176->Node) = t175);
  ((t177->age) = 6.284896357);
  ((t177->left) = t176);
  ((t177->right) = t170);
  ((t178->constr) = Node);
  ((t178->Node) = t177);
  ((t179.age) = 0.);
  ((t180->constr) = Leaf);
  ((t180->Leaf) = t179);
  ((t181.age) = 0.);
  ((t182->constr) = Leaf);
  ((t182->Leaf) = t181);
  ((t183->age) = 3.934203877);
  ((t183->left) = t182);
  ((t183->right) = t180);
  ((t184->constr) = Node);
  ((t184->Node) = t183);
  ((t185->age) = 7.815689971);
  ((t185->left) = t184);
  ((t185->right) = t178);
  ((t186->constr) = Node);
  ((t186->Node) = t185);
  ((t187.age) = 0.);
  ((t188->constr) = Leaf);
  ((t188->Leaf) = t187);
  ((t189->age) = 10.32243059);
  ((t189->left) = t188);
  ((t189->right) = t186);
  ((t190->constr) = Node);
  ((t190->Node) = t189);
  ((t191->age) = 12.551924091);
  ((t191->left) = t190);
  ((t191->right) = t164);
  ((t192->constr) = Node);
  ((t192->Node) = t191);
  ((t193.age) = 0.);
  ((t194->constr) = Leaf);
  ((t194->Leaf) = t193);
  ((t195.age) = 0.);
  ((t196->constr) = Leaf);
  ((t196->Leaf) = t195);
  ((t197->age) = 4.788021775);
  ((t197->left) = t196);
  ((t197->right) = t194);
  ((t198->constr) = Node);
  ((t198->Node) = t197);
  ((t199.age) = 0.);
  ((t200->constr) = Leaf);
  ((t200->Leaf) = t199);
  ((t201->age) = 7.595901077);
  ((t201->left) = t200);
  ((t201->right) = t198);
  ((t202->constr) = Node);
  ((t202->Node) = t201);
  ((t203.age) = 0.);
  ((t204->constr) = Leaf);
  ((t204->Leaf) = t203);
  ((t205->age) = 9.436625313);
  ((t205->left) = t204);
  ((t205->right) = t202);
  ((t206->constr) = Node);
  ((t206->Node) = t205);
  ((t207.age) = 0.);
  ((t208->constr) = Leaf);
  ((t208->Leaf) = t207);
  ((t209.age) = 0.);
  ((t210->constr) = Leaf);
  ((t210->Leaf) = t209);
  ((t211->age) = 5.635787971);
  ((t211->left) = t210);
  ((t211->right) = t208);
  ((t212->constr) = Node);
  ((t212->Node) = t211);
  ((t213->age) = 12.344087935);
  ((t213->left) = t212);
  ((t213->right) = t206);
  ((t214->constr) = Node);
  ((t214->Node) = t213);
  ((t215->age) = 13.472886809);
  ((t215->left) = t214);
  ((t215->right) = t192);
  ((t216->constr) = Node);
  ((t216->Node) = t215);
  ((t217->age) = 34.940139089);
  ((t217->left) = t216);
  ((t217->right) = t126);
  ((tree1->constr) = Node);
  ((tree1->Node) = t217);
  (rho = 0.568421052632);
  (inf = (1. / 0.));
  (numLeaves = countLeaves(tree1));
  (t245 = (( double ) numLeaves));
  (t246 = (t245 - 1.));
  (t247 = log1(2.));
  (t248 = (t246 * t247));
  (t249 = logFactorial(numLeaves));
  (t250 = (t248 - t249));
  FIRST_BBLOCK(start);
  SMC(callback);
})