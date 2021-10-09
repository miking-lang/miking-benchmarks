import json

data = json.load(open('output/experiment0.json'))
for item in data:
    print(item['lweight'])
