
	.mmregs
	.include "rx-dsp.h"
	.text

start:

	rsbx	XF
	nop
	nop
	
	ssbx	INTM
	stm		#0x2700, SP		; set Stack Pointer
	stm		#npmst,	PMST	; Set processor mode/status
	rsbx	SXM		; Suppress sign extension 
	nop
	ssbx	XF
	nop
	nop
	rsbx	XF
	nop

	nop
	nop
	
;	stm		#(tspc_Free+tspc_fsm+tspc_nXrst+tspc_nRrst), TSPC
	stm		#(tspc_Free+tspc_fsm), TSPC

	nop
	nop
	
	stm		#(int_3), IMR
	
	stm		#lsb_sel, AR0
	portw	AR0, wr_disc
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	
major_loop:
	
;	ssbx	

	; Raise test2 line.  On the Master this should do nothing (NC),
	; on the Slaves it signals the Master they are ready.

	stm		#(acq_seq_rdy+lsb_sel), AR0
	portw	AR0, wr_disc
	nop
	nop
	
	; Check status of TSP, wait for IN0 & IN1 high
ready_loop:

	nop
	
	bitf	TSPC, #tspc_in0
	bc		ready_loop, NTC
	
	bitf	TSPC, #tspc_in1
	bc		ready_loop, NTC
	
	; Raise acq_seq_out--on the Master this signals the Slaves to start, 
	; on the Slaves it does nothing (NC)--then start a major frame.
	
	stm		#(acq_seq_out+acq_seq_rdy+lsb_sel), AR0 ; send acq_seq_out, keep lsb_sel
	portw	AR0, wr_disc
	
	ssbx	XF
	rpt		#4096
	nop
	rsbx	XF
	
	stm		#(lsb_sel), AR0
	portw	AR0, wr_disc
	nop
	nop	

;	idle 	3

	portr	rd_disc, AR0
	bitf	AR0, #(acq_seq_in)
	bc		slave_skip, NTC
	
	
	ssbx	XF
	rpt		#50
	nop
	rsbx	XF	
	
slave_skip:

	nop

	b		major_loop

main_loop_end:

	.end