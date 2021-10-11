#!/bin/sh

time BIRCH_MODE="release" birch infer --nparticles 10000 | python logz.py
