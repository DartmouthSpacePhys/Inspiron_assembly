#!/usr/bin/python

from sys import argv
from struct import unpack

ifile = open(argv[1],'r')

for line in ifile:
    num = int(line[1:3], 16)
    addr = int(line[3:7], 16)
    type = int(line[7:9], 16)
    data = line[9:9+2*num]
    cs = int(line[-3:-1], 16)
    checksum = ~(int(line[1:-2], 16)%256) + 1

    print num, "0x%0.4X"%addr, type, data
#    if cs == checksum:
#        print num, addr, type, data, cs
#    else:
#        print num, addr, type, data, cs, checksum, "!"
        

