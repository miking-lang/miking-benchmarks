import json

data = json.load(open('output/output.json'))
for item in data:
    print(item['lweight'])
