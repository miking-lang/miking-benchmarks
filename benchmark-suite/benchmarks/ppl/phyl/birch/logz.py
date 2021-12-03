import sys
import json

data = json.load(sys.stdin)
#for item in data:
#    print(item['lweight'])
print(data[0]['lweight'])
