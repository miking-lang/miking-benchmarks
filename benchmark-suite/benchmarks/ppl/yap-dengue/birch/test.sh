#!/bin/sh

BIRCH_MODE="release" birch sample --config config/config20000.json --quiet true && python logz.py
