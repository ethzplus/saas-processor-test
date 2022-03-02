import json
import logging
import os
import sys
import time

logger = logging.getLogger('test-proc')

def feature_count(working_directory):
    with open(os.path.join(working_directory, 'a'), 'r') as f:
        a = json.load(f)
        count = len(a["features"])
        print(count)

    b = {
        'count': count
    }

    with open(os.path.join(working_directory, 'b'), 'w') as f:
        json.dump(b, f, indent=4, sort_keys=True)

if __name__ == '__main__':
    feature_count(sys.argv[1])
