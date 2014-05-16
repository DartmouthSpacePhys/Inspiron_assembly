#!/usr/bin/env python

import serial,signal,sys,time
from struct import unpack,pack
from datetime import datetime
import numpy as np
#import Gnuplot
#from matplotlib import pyplot as plt
from optparse import OptionParser

parser = OptionParser(usage="""tridsp-acq.py: read in triple-DSP multiplexed serial data.""")

parser.set_defaults(verbose=False,port="/dev/ttyS0", ofp="SStridsp", nboards=3, 
						majfsync=0xFE6B2840, majfsz=4, minfsz=524,
						filesync=0xb0f919c5025d, acqsz=4080, rtd=True)

parser.add_option("-o", "--outfile", type="str", dest="ofp", help="Output file prefix.  [default: %default]")
parser.add_option("-p", "--port", type="str", dest="port", help="Serial port number.  [%default]")
parser.add_option("-r", "--rtd", action="store_true", dest="rtd", help="Write out major frames for RTD. [%default]")
parser.add_option("-n", "--nboards", type="int", dest="nboards", help="Number of multiplexed DSP boards.  [%default]")
parser.add_option("-s", "--maj-sync", type="int", dest="majfsync", help="Major frame sync pattern.  [%default]")
parser.add_option("-z", "--maj-size", type="int", dest="majfsz", help="# of Minor frames per Major frame.  [%default]")
parser.add_option("-Z", "--min-size", type="int", dest="minfsz", help="# of bytes per Minor frame.  [%default]")
parser.add_option("-v", "--verbose", action="store_true", dest="verbose",
                help="print status messages to stdout.")

(o, args) = parser.parse_args()

o.majfsync = pack("4B", *[(o.majfsync>>i)&0xFF for i in [24,16,8,0]])
o.filesync = pack("6B", *[(o.filesync>>i)&0xFF for i in [40,32,24,16,8,0]])

try:
    inp = serial.Serial(port=o.port, baudrate=115200, bytesize=8, parity='N', stopbits=1)
except serial.SerialException:
	print "Unable to open serial port {0}.".format(o.port)
	sys.exit(1)

print("Reading from serial port {0}...".format(o.port))
		
dtstr = datetime.today().strftime("%Y%m%d-%H%M%S")

ofn = "{0}-{1}.data".format(o.ofp, dtstr)
ofile = open(ofn, "w")

print("Writing data to {0}...".format(ofn))

if o.rtd:
	rfile = open("/tmp/trirtd.data", 'w')

print("Writing RTD data to /tmp/trirtd.data...")

framecount = 0
bytestr = ""
mfbsync = "".join([o.majfsync[i]*o.nboards for i in range(len(o.majfsync))])
mfbsize = o.nboards*o.majfsz*o.minfsz

running = True
while running:
	data = inp.read(o.acqsz)
	
	# build timestamp: 40-bit uint seconds since epoch, 24-bit uint microseconds
	timefl = time.time()
	timeint = int(timefl)
	timefrac = int((timefl-timeint)*(1e6))
	timestr = ( pack(">Q", timeint&0xFFFFFFFFFF)[3:] ) + ( pack(">I", timefrac)[1:] )
	
	ofile.write(o.filesync)
	ofile.write(pack('>H', framecount&0xFFFF))	# 16-bit counter
	ofile.write(timestr)
	ofile.write(data)
	
	framecount += 1
	
	# if we want rtd, add to bytestream, and if there's a major frame in there, write it

	if o.rtd:
		bytestr += data
		
		loc = bytestr.find(mfbsync)
		nloc = bytestr.find(mfbsync, loc+1)
		
		if (loc >= 0) and (nloc >= loc):
			rfile.seek(0)
			rfile.write(bytestr[loc-4*o.nboards:nloc-4*o.nboards])
			rfile.flush()
#			prelen = len(bytestr)
			bytestr = bytestr[nloc-4*o.nboards:]
#			postlen = len(bytestr)
#			print("Wrote RTD file. {0} -> {1}".format(prelen,postlen))

if o.rtd:
	rfile.close()
ofile.close()
