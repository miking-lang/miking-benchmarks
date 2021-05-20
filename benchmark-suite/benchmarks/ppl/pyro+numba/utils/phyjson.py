import json


def read_tree(fname):
    def process(node, parent_id=None):
        nonlocal current_id
        node_id = current_id
        current_id += 1
        res = []
        for child in node.get('children', []):
            res += process(child, node_id)
        res = [{
            'id': node_id,
            'parent_id': parent_id,
            'has_children': True if res else False,
            't_beg': max(0., node['branch_length']) + (res[0]['t_beg'] if res else 0.),
            't_end': res[0]['t_beg'] if res else 0.
        }] + res
        return res
    current_id = 1
    fcontent = json.load(open(fname, 'r'))
    return process(fcontent['trees'][0]['root'])
