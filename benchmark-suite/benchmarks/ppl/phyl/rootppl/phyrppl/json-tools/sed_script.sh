#!/bin/bash
# replace tree with first argument and rho wtih second argument
sed "s/bisse32/$1/g" TEMPLATE_crbd.cu | sed "s/\(const floating_t rhoConst = \)\([[:digit:]]*\.[[:digit:]]\+\)/\1$2/g" 
