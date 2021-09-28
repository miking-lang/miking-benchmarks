#!/usr/bin/env python

import sys
import json

try:
    data = json.load(open("output/experiment0.json"))
    print(data[0]['lweight'])
except:
    print("NaN")
