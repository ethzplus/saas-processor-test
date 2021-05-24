import traceback
import logging
import os
import sys

logger = logging.getLogger('testing.20210602-demo')


def function(working_directory):
    status_path = os.path.join(working_directory, 'status.log')
    with open(status_path, 'w') as status:
        try:
            in_path = os.path.join(working_directory, 'confidential')
            with open(in_path, 'r') as f:
                # read the header
                header = f.readline()
                status.write(f"{header}\n")

                result = []
                for t in range(24):
                    line = f.readline()
                    print(line)

                    line = line.split(',')
                    s = 0
                    for i in range(1, len(line)):
                        s += float(line[i])

                    result.append(s)

            status.write(f"{result}\n")

            out_path = os.path.join(working_directory, 'aggregated')
            status.write(f"out_path={out_path}\n")
            with open(out_path, 'w') as f:
                f.write("Time,Aggregated\n")

                for t in range(24):
                    f.write(f"{t},{result[t]}\n")

            status.write(f"done\n")

        except Exception as e:
            trace = ''.join(traceback.format_exception(None, e, e.__traceback__))
            status.write(trace)


if __name__ == '__main__':
    function(sys.argv[1])
