#!/usr/bin/env python

from glob import glob
import json


def process(node):
    if 'children' in node:
        node['children'] = sorted(node['children'], key=lambda x: length(x))
        for child in node['children']:
            process(child)


def length(node):
    l = max(0.0, node['branch_length'])
    for child in node.get('children', []):
        l += length(child)
    return l


for tree in glob('*.phyjson'):
    data = json.load(open(tree, 'r'))
    process(data['trees'][0]['root'])
    json.dump(data, open('optimal/' + tree, 'w'), ensure_ascii=False, indent=4)
