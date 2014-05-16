from os.path import getmtime

def	b2iq(indat):
	# input	: binary string containing 16-bit big-endian signed I/Q data
	# output: [[I array], [Q array]]
	
	num = unpack(">"+str(len(indat)/2)+"h", indat)
	return np.reshape(num, (2,-1), "F")

running = True
while running:

	while True:
		newtime = getmtime(o.ifn)
		if newtime != oldtime:
			break
	
	infile.seek(0)
	data = infile.read()
	nums = b2iq(data)
	
	# check for good frame
	
	
	# parse major frames and plot
	cfs = []
	eyes = [[]]*o.nboards
	ques = [[]]*o.nboards
	for i in range(o.nboards):
		majf = []
		bshift = i*o.majfsz*o.minfsz/2
		for j in range(o.majfsz):
			majf.extend(nums[bshift+4:bshift+4+o.minfsz/2]) # extract majf from minf
		
		# we can haz major frame
		cfreq = (unpack(">I", pack(">hh", *majf[8:10])))
		cfkhz = int(round(cfreq/2**32*66666.6,3))
		cfs[i].append(cfkhz)
		
		majdat = majf[16:]
		
		for i in range(len(majdat)/2):
			eyes[i].append(majdat[2*i])
			ques[i].append(majdat[2*i+1])

	if len(np.unique(cfkhz))) != 1:
		print("Mismatched center frequencies!")
		
	dfdb = o.bw/512.0
	freqlist = range(cfs[i]-o.bw/2.0, cfs[i]+o.bw/2.0, dfdb)
	
	
	fftdata = []
	for i in range(o.nboards):
		for j in range(len(eyes[i])):
			fftdata.append(eyes[i][j]+ques[i][j]*1j)
		
		spec = [10.0*y for y in np.log10([abs(x)^2 for x in np.fft.fft(fftdata)])]	# power spectra
		spec = spec[len(spec)/2:]+spec[:len(spec)/2]	# swap from normal order
		
		
				
                        words = unpack('>1024h', pack('2048B', *data[32:2080]))
                        eyes = []
                        ques = []
                        for i in range(512):
                            eyes.append(words[2*i])
                            ques.append(words[2*i+1])
                        g('set xrange [0:512]')
                        g('set yrange [-32768:32768]')
                        g.plot(eyes, ques)
