
	.mmregs
	.include "rx-dsp.h"
	.text

start:

	stm		#(int_3), IMR
	ssbx	INTM
	
	

main_loop:

ready_loop:

	nop
	nop
	bitf	TSPC, #(tspc_in0+tspc_in1)	; check for S1 & S2 ready
	bc		ready_loop, NTC
	
	stm		#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc
	nop
	nop
	
	ssbx	XF
	rpt		#4096
	nop
	rsbx	XF
	
	stm		#(lsb_sel), AR0
	portw	AR0, wr_disc
	nop
	nop	

	idle 	3

	

	b		main_loop

main_loop_end:

	.end
