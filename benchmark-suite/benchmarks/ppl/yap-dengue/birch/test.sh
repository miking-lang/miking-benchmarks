#!/bin/sh

BIRCH_MODE="release" birch sample --config config/experiment0.json --quiet true && python logz.py
