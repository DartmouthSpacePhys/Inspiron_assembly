	.mmregs
	.include	"rx-dsp.h"
	.text

start:

	stm		#(int_3), IMR
	ssbx	INTM
	
	

main_loop:

	stm		#(acq_seq_rdy+lsb_sel), AR0 ; send acq_seq_rdy, set lsb_sel
	portw	AR0, wr_disc
	nop
	nop
	
ready_loop:

	portr	rd_disc, AR0
	nop
	nop
	bitf	AR0, #acq_seq_in	; wait for acq_seq
	bc		ready_loop, NTC
	
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