import logging
import os

logger = logging.getLogger('testing.20210602-demo')


def function(working_directory):
    in_path = os.path.join(working_directory, 'confidential')
    with open(in_path, 'r') as f:
        # read the header
        header = f.readline()
        print(header)

        result = []
        for t in range(24):
            line = f.readline()
            print(line)

            line = line.split(',')
            s = 0
            for i in range(1, len(line)):
                s += float(line[i])

            result.append(s)

    print(f"result: {result}")

    out_path = os.path.join(working_directory, 'aggregated')
    with open(out_path, 'w') as f:
        f.write("Time,Aggregated\n")

        for t in range(24):
            f.write(f"{t},{result[t]}\n")
