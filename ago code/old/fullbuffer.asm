;*****************************************************************************
;
; Dartmouth College AGO Rx-DSP Program
;
; Written by: Micah P. Dombrowski and Nathan B. Utterback
;     w/ code segments from TI DSP Library
;
;*****************************************************************************

	.mmregs
	.global ZERO, BMAR, PREG, DBMR, INDX, ARCR, TREG1
	.global TREG2, CBSR1, CBER1, CBSR2, CBER2
	.global RXDSP_START
	.ref	_RxDSP_Monitor, _cfft1024, _log_10
	.text
			
	.include "rx-dsp.h"
	.include "int_table.h"
	.text

; Run constants	
data_addr		.set	1000h	; Where to store data for FFTing
data_n			.set	1024	; Size of each FFT (# of IQ pairs)
data_discard	.set	0		; number of words to discard from Rx FIFO before taking data
data_minor_sz	.set	1 		; number of acquisitions per half-buffer interrupt
abu_buff_loc	.set	0x0800	; serial buffer start location
abu_buff_hloc	.set	0x0A00	; half-way
abu_buff_sz		.set	1024	; size of serial buffer (2x major frame size IN BYTES)
fsync_sz		.set	4		; # of serial frame sync bytes (should be multiple of 4)
bridge_sz		.set	2048	;

RXDSP_START
ago_main:

	rsbx	XF

; Processor setup
	ssbx    INTM		; Disable interrupts 
	stm	#stack,SP	; set Stack Pointer
	stm	#npmst,PMST	; Set processor mode/status
;	stm #defst0, ST0
;	stm	#defst1, ST1
	rsbx	SXM		; Suppress sign extension 
;	rsbx	XF
	nop			; Space for branch to app
	nop
 
appcode:
;	stm	#0,state	; Clear interrupt routine state
	stm	#0,AR0		; Clear auxilliary register 0
	portw	AR0,wr_rs_rx	; Reset AD6620 RSP
	portw	AR0,wr_disc	; Enable parallel TLM drivers, I_Q out
	portw	AR0,wr_dog	; Strobe watchdog timer
	
	stm	#0,AR0	; Clear all auxiliary registers
	stm	#0,AR1
	stm	#0,AR2
	stm	#0,AR3
	stm	#0,AR4
	stm	#0,AR5
	stm	#0,AR6
	stm	#0,AR7

	stm		#0FFh,IFR	; Clear any pending interrupts
	stm	#ntss,TCR	; Stop timer, if running
		
; Main data code start
read_init:
	ld		#ad6620_soft_reset, A ; Put AD6620 into reset
	call	rsp_setup
	nop

	ld		#ad6620_filter,A ; Set up AD6620 filter
	call	rsp_setup
	nop
	
	call	rsp_clear
	nop

	ld		#ad6620_master_run, A	; Start digitizing as master
	call	rsp_setup
	nop
	
	rpt		#4444	; Let the AD6620 do its first initialization in peace
	nop
	
	rpt		#2048
	portr	rd_rx_out, AR0	; read data directly into memory
	nop
	
	ld		#ad6620_soft_reset, A ; Put AD6620 into reset
	call	rsp_setup
	nop
	
	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
	nop
	nop	

	stm		#lsb_sel, AR0			; Reset discrete outputs (acq_seq & lsb_sel)
	portw	AR0, wr_disc
	nop
	
	; BSP prep

	stm		#(bspc_fsm), BSPC0 		; reset BSP
	stm		#(int_3+int_bx), IMR			; unmask serial transmit interrupt
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx autobuffer
	stm		#(abu_buff_loc-0x800), AXR		; where in the 2048 words of buffer RAM 
											; does the transmit buffer start?
	stm		#(abu_buff_sz), BKX				; 
	
; Clear entire serial buffer
	stm		#abu_buff_loc, AR4
	stm		#abu_buff_sz-1, BRC
	rptb	buff_init_loop - 1
	
	st		#3FFh, *AR4+
	
buff_init_loop:

; Write a header "test ramp" to first half buffer
	stm		#abu_buff_loc, AR4		; data address
	stm		#0, AR3				; data counter	
	stm		#abu_buff_sz/8-1, BRC
	rptb	head_ramp - 1
	
;	ldm		AR3, A
;	sftl	A, 1
;	or		#1, A
;	stl		A, *AR4+
	st		#0x1FF, *AR4+
	st		#0x001, *AR4+
	st		#0x1F0, *AR4+
	st		#0x001, *AR4+
;	mar		*AR3+
	
head_ramp:


; Write out header to first buffer half

;	stm	#abu_buff_loc, AR4
;	stm	#static_header,AR1	; Point to static header words
;static:
;	ld		*AR1+, A		; Get a word, point to next
;	stlm	A, AR0		; Check for end of static header
;	cmpm	AR0, #0		; Null terminator?
;	bc		static_x, TC		; If terminator, end static header
;	stl		A, *AR4+		; Write to serial buffer
;	b	static
;static_x:

; Set initial AR6 such that the first acquisition will
; write to the second half of the serial buffer
	stm		#bspce_xh, AR6
		
; Start BSP transmits
	stm		#(bspc_fsm + bspc_nXrst), BSPC0	; have to hold fsm bit

;	rsbx	INTM ; global interrupt enable
	
;	AR5		Bridged data output counter
;	AR6		Control Extension Register storage
;	AR7		minor frame counter
	
major_loop:
	
	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
	nop
	nop
		
	stm		#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc
	
	call	rsp_clear
	nop

	ld		#ad6620_master_run, A	; Start digitizing as master
	call	rsp_setup
	
;
; Reads
;
	stm		#0, AR5		; reset bridged data counter
	stm		#data_minor_sz, AR7 ; set minor frame counter
minor_loop:

;
; Set wait states for Rx FIFO
;
	ldm		SWWSR, A
	ld		#65535, B
	xor		#7, #swwsr_is, B ; (0b111<<Nset XOR 0d65535) creates bitmask
	and		B, A			 ; mask out bits of interest
	or		#0, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
	; Nwait = 0 means no additional waits
	stlm	A, SWWSR

	ssbx	XF
	rpt #100
	nop
	rsbx	XF
	
	
; loop to read and discard first data out of AD6620
	stm		#(data_discard-1), AR2

rx_discard_loop:
	; read only if rx fifo is nonempty
	portr	rd_disc, AR0
	nop
	nop
	bitf	AR0, rx_efo
	
	bc		discard_fifo_empty, NTC
	portr	rd_rx_out, AR1		; read data into AR1
	mar		*AR2-				; decrement word counter		
discard_fifo_empty:

	banz	rx_discard_loop, *AR2
	
	
; loop to read data from Rx FIFO into RAM
	stm		#data_addr, AR1	; set address for first data word
	stm		#(data_n*2-1), AR2

rx_read_loop:
	; read only if rx fifo is nonempty
	portr	rd_disc, AR0
	nop
	nop
	bitf	AR0, rx_efo
	
	bc		read_fifo_empty, NTC
	portr	rd_rx_out, *AR1+	; read data directly into memory
	mar		*AR2-				; decrement word counter	
read_fifo_empty:

	banzd	rx_read_loop, *AR2
	nop
	nop
	
;
; Set wait states for other stuff (full 7)
;
	ldm		SWWSR, A
	or		#7, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
	stlm	A, SWWSR
	nop
	nop
	
	ssbx	XF
	rpt #50
	nop
	rsbx	XF

; Load test pattern x 64
;	stm		#data_addr, AR1		; data address
;	stm		#(data_n-1), AR3	; data counter	
;	stm		#1023, BRC
;	rptb	testpatt_loop - 1
;	st		#0x5533, *AR1+
;	st		#0xAA00, *AR1+
	
; Load test ramp x 2048
;	stm		#data_addr, AR1		; data address
;	stm		#0, AR3				; data counter	
;	stm		#2047, BRC
;	rptb	testpatt_loop - 1
;	mvkd	AR3, *AR1+
;	mar		*AR3+

testpatt_loop:

	b	skip_bridge
bridge_data:	; entry point for bridging data transfers over multiple serial half-buffers
	stm		#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc
skip_bridge:

	nop
	nop
	; Determine serial buffer position
	stm		#abu_buff_loc, AR0	; load buffer base
	
	bitf	AR6, #bspce_xh 		; read XH out of stored BSPCE register
	bc		abu_first_half, NTC ; if first half _finished_ (XH=0), do nothing
	
	stm		#abu_buff_hloc, AR0 ; if second half finished (XH=1), load second half addr

abu_first_half:

	ssbx	INTM
	
	; Clear serial buffer half
	mvmm	AR0, AR4
	nop
	nop
	stm		#(abu_buff_sz/2-1), BRC
	rptb	buff_clear_loop - 1
	
	st		#0x00, *AR4+
	
buff_clear_loop:


	mvmm	AR0, AR4
	nop
	nop

		
	; two-byte frame sync 0xEB90
	ld		#0xFE, A
	stl		A, *AR4+
	ld		#0x6B, A
	stl		A, *AR4+
	ld		#0x28, A
	stl		A, *AR4+
	ld		#0x40, A
	stl		A, *AR4+

	; copy raw data (words) into serial buffer (bytes)
	ld		#data_addr, A
	add		AR5, A
	stlm	A, AR1
	stm		#((abu_buff_sz/2-fsync_sz)/2-1), BRC
	rptb	rawdata_loop - 1
	
	ld		*AR1, -8, A	; load (data word) >> 8 to Acc
	and		#0xFF, A	; mask to low-byte
	stl		A, *AR4+	; save to serial buffer
	
	ld		*AR1+, A 	; reload and increment
	and		#0xFF, A	; mask
	stl		A, *AR4+	; save

	mar		*AR5+
	nop
	cmpm	AR5, #bridge_sz
	bc		rawdata_bskip, NTC

	nop
	nop
	
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	
	nop
	nop
		
	rsbx	BRAF
	nop
	nop
	b		bitrev_start
	
	nop
	nop
	
rawdata_bskip:

	nop
	nop
	
rawdata_loop:

	nop
	nop

bitrev_start:

	nop
	nop
	
	; Bit reverse and add start & stop bits

	stm		#(abu_buff_sz/2-1), BRC
	rptb	bitrev_loop - 1

	ssbx	XF

	ld		#1, B			; zero result + stop bit
	
	ld		#001h, A	; load mask
	and		*AR0, A		; mask data
	or		A, 8, B		; OR into result
	ld		#002h, A
	and		*AR0, A
	or		A, 6, B
	ld		#004h, A
	and		*AR0, A
	or		A, 4, B
	ld		#008h, A
	and		*AR0, A
	or		A, 2, B
	ld		#010h, A
	and		*AR0, A
	or		A, 0, B
	ld		#020h, A
	and		*AR0, A
	or		A, -2, B
	ld		#040h, A
	and		*AR0, A
	or		A, -4, B
	ld		#080h, A
	and		*AR0, A
	or		A, -6, B

	stl		B, *AR0+			; rewrite to serial buffer
	
	rsbx	XF	
	
bitrev_loop:

;	rsbx	INTM
		
;dw_loop:
;	ld		*AR2+, A
;
;	ld		A, -8, B
;	sftl	B, 1
;	or		#512, B
;	stl		B, *AR1+
;	
;	sftl	A, 1
;	or		#512, A
;	stl		A, *AR1+
;	
;	banz	dw_loop, *AR3-

;	ld		#1FFh, A	; two 0xFF bytes for frame end
;	stl		A, *AR0+
;	stl		A, *AR0+

		
; If a major frame is complete, shut it down

; unset acq_seq, keep lsb_sel
	stm		#lsb_sel, AR0
	portw	AR0, wr_disc

; Strobe watchdog- once per acquisition
	stm		#0, AR0        ; Data is not used- just the wr_dog strobe
	portw	AR0,wr_dog     ; Strobe the watchdog

; Stop acquisition, clear interrupts, then idle until an interrupt.
	ld		#ad6620_soft_reset, A
	call	rsp_setup
	nop
	nop

pre_sleep:
	
	ssbx	XF
	rpt #50
	nop
	rsbx	XF
	rpt #100
	nop
	ssbx	XF
	rpt #50
	nop
	rsbx	XF
	
	ssbx	INTM
	stm		#0FFh,IFR		; Clear any pending interrupts
	
	idle	3	; and now...we wait.
	
; check for aux int -> serial monitor
	bitf	IFR, #int_3
	cc		inth_3, TC
	
; make sure we had a serial interrupt
;	bitf	IFR, #int_bx
;	bc		pre_sleep, NTC	; stray interrupt, go back to IDLE
	
	nop
		
	stm		#int_bx, IFR 	; clear int flag
	
	ldm		BSPCE0, A ; store control extension register in AR6
	stlm	A, AR6
	
	cmpm	AR5, #bridge_sz		; If we're not done with a bridged data sequence, 
	bc		bridge_data, NTC	; jump to bridge_data to continue transfers, otherwise...

	b		major_loop

;;
; Main acquisiton ('appcode') branch done
;;	

;;
; Interrupts
;;

inth_3:
	ssbx	INTM
	stm		#int_3, IFR 	; clear int flag

	; call serial monitor

	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	rpt #2000
	nop	
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	rpt #2000
	nop		
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	rpt #2000
	nop		
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	rpt #2000
	nop		
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	rpt #2000
	nop		
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	
	calld	_RxDSP_Monitor
	stm		#bspce_haltx, BSPCE	 ; tell serial transmit to halt after completing this half-buffer

	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	rpt #2000
	nop		
	ssbx	XF
	rpt #10000
	nop
	rsbx	XF
	
	retd
	nop
	nop


	.include "ad6620.asm"
