#!/usr/bin/env python

import serial,signal,sys
from struct import unpack,pack
from datetime import datetime
import numpy as np
#import Gnuplot
#from matplotlib import pyplot as plt
from optparse import OptionParser

parser = OptionParser(usage="""tridsp-acq.py: read in triple-DSP multiplexed serial data.""")

parser.set_defaults(verbose=False,port="/dev/ttyS0", ofp="SStridsp", nboards=3, 
						majfsync=0xFE6B2840, majfsz=4,
						minfsync=0xEB90, minfsz=524)

parser.add_option("-o", "--outfile", type="str", dest="ofp", help="Output file prefix.  [default: %default]")
parser.add_option("-p", "--port", type="str", dest="port", help="Serial port number.  [default: %default]")
parser.add_option("-n", "--nboards", type="int", dest="nboards", help="Number of multiplexed DSP boards.  [%default]")
parser.add_option("-s", "--maj-sync", type="int", dest="majfsync", help="Major frame sync pattern.  [%default]")
parser.add_option("-z", "--maj-size", type="int", dest="majfsz", help="# of Minor frames per Major frame.  [%default]")
parser.add_option("-S", "--min-sync", type="int", dest="minfsync", help="Minor frame sync pattern.  [%default]")
parser.add_option("-Z", "--min-size", type="int", dest="minfsz", help="# of bytes per Minor frame.  [%default]")
parser.add_option("-v", "--verbose", action="store_true", dest="verbose",
                help="print status messages to stdout.")

(o, args) = parser.parse_args()

o.majfsync = pack("4B", *[(o.majfsync>>i)&0xFF for i in [24,16,8,0]])
o.minfsync = pack("2B", *[(o.minfsync>>i)&0xFF for i in [8,0]])

try:
    inp = serial.Serial(port=o.port, baudrate=115200, bytesize=8, parity='N', stopbits=1)
except serial.SerialException:
	print "Unable to open serial port {0}.".format(o.port)
	sys.exit(1)

def collimate_string(instr, cols):
	# input: a string and a number of columns
	# output: a list of <cols> strings
	Nchar = len(instr)/cols
	trim = instr[:Nchar*cols]	# trim instr to be divisible by <cols>
	outcols = [""]*cols
	for i in range(Nchar):
		offt = cols*i
		for j in range(cols):
			outcols[j] += trim[offt + j]
	return(outcols)


def	extract_major(bytestream, nboards, majfsync, majfsz, minfsync, minfsz):
	# bytestream: multiplexed serial byte stream
	# nboards	: number of serial streams multiplexed within bytestream
	# majfsync	: value signaling start of major frame
	# majfsz	: number of minor frames in each major frame
	# minfsync	: value signaling end of minor frame
	# minfsz	: number of bytes per minor frame (overhead inc.)
	# returns [ int endpoint , <nboard x (majfsz*minfsz) word data array> ]
	# endpoint	: amount of data consumed, or (on error) -<bytes searched with no good result>
	#			  either way, probably want to toss bytestream[:abs(endpoint)]
	# data array: left in binary string form, suitable for writing to files
	
	tsize = nboards * majfsz * minfsz
	
	# search stream until there's not enough left to hold a full frame
	for sshift in range(len(bytestream)-tsize):
		
		badness = False
		
		# reshape into n-stream lists
		# for speed, use a <tsize> chunk, plus <128*nboards> padding for weirdness
		bss = collimate_string(bytestream[sshift:sshift+tsize+nboards*128], nboards)
		
		syncpos = [0]*nboards
		for i in range(nboards):
			syncpos[i] = bss[i].find(minfsync)
		
		# check startup sync positions
		syncposuv = unique(syncpos)
		if len(syncposuv) != 1:
			print("Boards out of sync...")
			
		for i in range(nboards):
			if syncposuv[0] != 0:
				print("Pre-sync hash in stream {0}.".format(i))
		
		# check that there are minor syncs in the proper positions,
		# with proper counters
		claimed_units = [[-1]*majfsz]*nboards
		for i in range(nboards):
		
			for j in range(majfsz):
				pos = j*minfsz + syncpos[i]
			
				if bss[i][pos:pos+2] != minfsync:
					print("Stream {0} missing minor frame sync #{1}.".format(i,j))
					badness = True
					break
				
				min_counter = unpack("B",bss[i][pos+2])
				claimed_units[i][j] = min_counter>>6
				min_counter = min_counter&0b111111
				
				if min_counter != j:
					print("Stream {0} minor frame counter desync.".format(i))
					badness = True
					break
					
			# end for j in range(majfsz)
			
			streamunit = list(unique(claimed_units[i]))
			if len(streamunit) != 1:
				print("Stream {0} claimed unit desync.".format(i))
				badness = True
				break
				
			claimed_units[i] = streamunit
			
			if badness: # I break for deeper level errors
				break
			
		# end for i in range(nboards)
		
		if list(unique(claimed_units)) != range(nboards):
			print("Unit numbering failure, found {0}".format(claimed_units))
			badness = True
		
		if badness:
			continue
			
		else:
			break
			
	# end for sshift in range()

	if badness:
		# if there's a lingering badness flag, we ran out of data before finding a good major frame.  we are sad :(
		return([ -len(bytestream)-tsize , 0])
	
	# If we reach this point, we seem to have a sane set of n major frames.  extract the data
	
	dss = [list(reshape( [bss[i][syncpos[i]+j*minfsz+4:syncpos[i]+(j+1)*minfsz] for j in range(majfsz)], (-1))) for i in range(nboards)]
	dsr = [[] for i in range(nboards)]
	for i in range(nboards):
		dsr[claimed_units[i]] = dss[i]
	
	endpoint = sum(syncpos) + nboards*majfsz*minfsz
	
	return([ endpoint , dsr ])
		
dtstr = datetime.today().strftime("%Y%m%d-%H%M%S")

outf = []
for i in range(o.nboards):
	ofn = "{0}-{1}-u{2}.data".format(o.ofp, dtstr, i)		
	outf.append(open(ofn, "w"))


synclocs = [0,0,0]
synclocn = [0,0,0]
ounit = [0,0,0]

bytestr = inp.read(o.nboards * o.majfsz * o.minfsz * 3)

running = True
while running:
	endpoint, data = extract_major(bytestr, o.nboards, o.majfsync, o.majfsz, o.minfsync, o.minfsz)
	
	bytestr = bytestr[abs(endpoint):]
	bytestr += inp.read(abs(endpoint))
	print("Disc/read {0} bytes.".format(abs(endpoint)))
	
	if endpoint < 0:
		print("Failed to find major frame.")
		continue

	badness = False
	for i in range(o.nboards):
		if data[i][0:4] != "\xFE\x6B\x28\x40":
			print("Missing sync in Unit {0} major frame?".format(i))
			badness = True
			
		if data[i][9] != i:
			print("Major/minor frame claimed unit mismatch, Unit {0} ({1}?!).".format(i,data[i][9]))
			badness = True
				
	if badness:
		continue

	# build timestamp: 44-bit uint seconds since epoch, 20-bit uint microseconds
	timefl = time.time()
	timeint = int(timefl)
	timefrac = (timefl-timeint)*(1e6)
	timestr = ( pack(">Q", timeint) ) & ( pack(">I", timefrac)<<12 )
	
	# write new data to file w/ a timestamp
	for i in range(o.nboards):
		outf[i].write(data[i])
		outf[i].write(timestr)

	# write to rtd file if desired
	if o.dt > 0:
		rtdf.seek(0)
		for i in range(o.nboards):
			rtdf.write(data[i])
		rtdf.write("FRAMEEND")
		rtdf.flush()
	
	
