import json
import logging
import os
import sys
import time

logger = logging.getLogger('test-proc')

def feature_count(working_directory):

    print(f"trigger:progress:0")

    with open(os.path.join(working_directory, 'a'), 'r') as f:
        a = json.load(f)
        count = len(a["features"])
        print(count)

    print(f"a={a}")
    print(f"trigger:progress:33")

    b = {
        'count': count
    }

    print(f"b={b}")
    print(f"trigger:progress:66")

    with open(os.path.join(working_directory, 'b'), 'w') as f:
        json.dump(b, f, indent=4, sort_keys=True)

    print(f"trigger:output:b")
    print(f"trigger:progress:100")

if __name__ == '__main__':
    feature_count(sys.argv[1])
