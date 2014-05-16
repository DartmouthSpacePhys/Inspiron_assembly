#!/usr/bin/env python
from os.path import getmtime
import sys
from struct import unpack,pack
from datetime import datetime
import numpy as np
import Gnuplot
#from matplotlib import pyplot as plt
from optparse import OptionParser

parser = OptionParser(usage="""tridsp-acq.py: read in triple-DSP multiplexed serial data.""")

parser.set_defaults(verbose=False, rfile="/tmp/trirtd.data", nboards=3, 
						majfsync=0xFE6B2840, majfsz=4,
						minfsync=0xEB90, minfsz=524, dataplot=True)

parser.add_option("-r", "--rfile", type="str", dest="rfile", help="RTD data file.  [default: %default]")
parser.add_option("-n", "--nboards", type="int", dest="nboards", help="Number of multiplexed DSP boards.  [%default]")
parser.add_option("-s", "--maj-sync", type="int", dest="majfsync", help="Major frame sync pattern.  [%default]")
parser.add_option("-z", "--maj-size", type="int", dest="majfsz", help="# of Minor frames per Major frame.  [%default]")
parser.add_option("-S", "--min-sync", type="int", dest="minfsync", help="Minor frame sync pattern.  [%default]")
parser.add_option("-Z", "--min-size", type="int", dest="minfsz", help="# of bytes per Minor frame.  [%default]")
parser.add_option("-v", "--verbose", action="store_true", dest="verbose",
                help="print status messages to stdout.")

(o, args) = parser.parse_args()
def	b2iq(indat):
	# input	: binary string containing 16-bit big-endian signed I/Q data
	# output: [[I array], [Q array]]
	
	num = unpack(">"+str(len(indat)/2)+"h", indat)
	return np.reshape(num, (2,-1), "F")

cplotd = {}
blist = range(o.nboards)

infile = open(o.rfile, 'r')

oldtime = 0

running = True
while running:

	while True:
		newtime = getmtime(o.rfile)
		if newtime != oldtime:
			break
	
	oldtime = newtime
	badness = False

	infile.seek(0)
	data = infile.read()
	
	# check for good frame
	
	
	# parse major frames and plot
	
	unitdata = [[]]*o.nboards
	
	for i in blist:
		bdata = data[i::o.nboards]
		majfr = "".join([bdata[j*o.minfsz+4:(j+1)*o.minfsz] for j in range(o.majfsz)]) # extract major frame
		minsyncs = "".join([bdata[j*o.minfsz:j*o.minfsz+4] for j in range(o.majfsz)])	#extract minor frame syncs

		minunit = [(x & 0xC0)>>6 for x in unpack(">4B", minsyncs[2::4])]
		if len(np.unique(minunit)) != 1:
			print("Minor frame Unit number mismatch.")
			badness = True
		
		minmajN = unpack(">4B", minsyncs[3::4])
		if len(np.unique(minmajN)) != 1:
			print("Minor frames' major frame # mismatched.")
			badness = True
		
		unit = unpack("B", majfr[9])[0]-0x30
		if unit != np.unique(minunit)[0]:
			print("Major frame doesn't match minor frame Unit #.")
			badness = True
			
		majN = unpack(">I", majfr[24:28])[0]&0xFF	
		if majN&0xFF != np.unique(minmajN)[0]:	# mask to one-byte to test against minor frame #
			print("Major frame # doesn't match minor frames' major frame #.")
			badness = True
		
		# looks like a good major frame
		
		cfreq = int(round(unpack(">I", majfr[16:20])[0]/2.0**32*66666.6))
		nums = unpack(">"+str(len(majfr)/2-16)+"h", majfr[32:])
		
		unitdata[unit] = {	'cfreq' : cfreq,
						'eyes' : nums[::2],
						'ques' : nums[1::2] }
	
	
	if len(np.unique([ x['cfreq'] for x in unitdata ])) != 1:
		print("Center frequency mismatch!")

	if badness:
		continue

	cfreq = unitdata[0]['cfreq']

	# can has dataz, now to plot
	
	if o.dataplot:
		# first mode: print I/Q data, one plot, Is and Qs overlapped, Qs shifted -65536
	
		# check frequency <=> plot list
		if cfreq not in cplotd.keys():
			cplotd[cfreq] = Gnuplot.Gnuplot()
			cplotd[cfreq]("set xrange [0:512]")
			cplotd[cfreq]("set yrange [-98304:32768]")
			cplotd[cfreq]("set style data lines")
			cplotd[cfreq]("set title \"{0} KHz\"".format(cfreq))

		dary = []
		for i in blist:
			pdat = unitdata[i]['eyes']
			pdx = range(len(pdat))
			dary.append( Gnuplot.Data(pdx, pdat, title="Unit "+str(i)+" I") )

			pdat = [x-65536 for x in unitdata[i]['ques']]
			pdx = range(len(pdat))
			dary.append( Gnuplot.Data(pdx, pdat, title="Unit "+str(i)+" Q") )
		cplotd[cfreq].plot(*dary)

	

	elif o.spectra:
		dfdb = o.bw/512.0
		freqlist = range(cfs[i]-o.bw/2.0, cfs[i]+o.bw/2.0, dfdb)

		[eyes[j]+ques[j]*1j for j in range(len(eyes))]
		fftdata = []
		for i in range(o.nboards):
			for j in range(len(eyes[i])):
				fftdata.append(eyes[i][j]+ques[i][j]*1j)
		
		spec = [10.0*y for y in np.log10([abs(x)^2 for x in np.fft.fft(fftdata)])]	# power spectra
		spec = spec[len(spec)/2:]+spec[:len(spec)/2]	# swap from normal order
#                        g.plot(eyes, ques)
