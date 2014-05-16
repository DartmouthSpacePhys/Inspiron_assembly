	; test code to read a filter coef from the RCF coef ram
	; turns out it really doesn't matter what we put in the high bytes
	stm		#0x00, AR0
	portw	AR0, wr_rx+amr
	
	stm		#0x09, AR0
	portw	AR0, wr_rx+lar
	
	portr	rd_rx+dr0, AR0
	portr	rd_rx+dr1, AR1
	portr	rd_rx+dr2, AR2
	portr	rd_rx+dr3, AR3
	portr	rd_rx+dr4, AR4
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
craycray:
	.global	craycray
	nop
