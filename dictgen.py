#!/usr/bin/python

import math
import sys

try:
    start = int(sys.argv[1])
    print("1: ", sys.argv[1])
    end = int(sys.argv[2])
    print("2: ", sys.argv[2])
    out = sys.argv[3]
    print("3: ", sys.argv[3])
except (IndexError, ValueError):
    print("usage: python dictgen.py from to outfile\n")
    sys.exit(-1)
template = "{:0%dd}\n" % math.log10(end) # number of decimal digits
with open(out, "wb") as out_file:
    out_file.writelines(template.format(num) for num in xrange(start, end))


