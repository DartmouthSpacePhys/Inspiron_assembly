fifo = [inp.read(4096)]
while running:
	base = fifo.find(o.sync)
	minend = fifo.find(o.sync, base+1)
	
	if base == -1 or minend == -1:
		fifo += inp.read(1024)
		continue
		 
	if fifo[base+2] == 0:
		plot(majframe)
		majframe = ""

	majframe += fifo[base+2:minend]		
	fifo = fifo[majframe:]
	fifo += inp.read(minend-base)
