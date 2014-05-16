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
	.text
	
	.include "rx-dsp.h"
	.include "int_table.h"

; Run constants	
data_addr		.set	1800h	; Where to store data for FFTing
data_n			.set	225	; Size of each FFT (# of IQ pairs)
data_2n			.set	450	; Size of each FFT (# of words)
data_minor_sz	.set	1 		; number of acquisitions per half-buffer interrupt
abu_buff_loc	.set	0800h	; serial buffer start location
abu_buff_sz		.set	904	; size of serial buffer (2x minor size)
abu_buff_hsz	.set	452		; half size of serial buffer (minor size)

	rsbx	XF

; Processor setup
	ssbx    INTM		; Disable interrupts 
	stm	#stack,SP	; Stack pointer to high RAM
	stm	#npmst,PMST	; Set processor mode/status
	rsbx	SXM		; Suppress sign extension 
	nop			; Space for branch to app
	nop
 
appcode:
	ssbx	INTM
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

	ld		#ad6620_filter,A ; Set up AD6620 filter
	call	rsp_setup

	stm		#0, AR0			; Reset discrete outputs (acq_seq & lsb_sel)
	portw	AR0, wr_disc

	stm		#(bspc_fsm), BSPC0 		; reset BSP
	stm		#int_bx, IMR			; unmask serial transmit interrupt
	rsbx	INTM ; global interrupt enable
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx autobuffer
	stm		#(abu_buff_loc), AXR	
	stm		#(abu_buff_sz), BKX
	
; Write out header to first buffer half

	stm	#abu_buff_loc, AR5
	stm	#static_header,AR1	; Point to static header words
static:
	ld		*AR1+, A		; Get a word, point to next
	stlm	A, AR0		; Check for end of static header
	cmpm	AR0, #0		; Null terminator?
	bc		static_x, TC		; If terminator, end static header
	stl		A, *AR5+		; Write to serial buffer
	b	static
static_x:

; Set initial AR6 such that the first acquisition will
; write to the second half of the serial buffer
	stm		#bspce_xh, AR6
		
; Start BSP transmits
	stm		#(bspc_fsm + bspc_nXrst), BSPC0	; have to hold fsm bit

;	AR6		Control Extension Register storage
;	AR7		minor frame counter
	
major_loop:
	
	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
	nop
	nop
		
	stm		#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc

	ld		#ad6620_master_run, A	; Start digitizing as master
	call	rsp_setup

;
; Reads
;
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
	
; loop to read data from Rx FIFO into RAM
	stm		#data_addr, AR1	; set address for first data word
	stm		#(data_2n-1), AR2

rx_read_loop:

; skip read if rx fifo is empty
	portr	rd_disc, AR0
	nop
	nop
	bitf	AR0, rx_efo
	bc		fifo_empty, NTC

	portr	rd_rx_out, *AR1+	; read data directly into memory
	mar		*AR2-
	
fifo_empty:
	
	banz	rx_read_loop, *AR2
	
;
; Set wait states for other stuff (full 7)
;
	ldm		SWWSR, A
	or		#7, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
	stlm	A, SWWSR
	nop
	nop
		
	; Call FFT Function

	stm		#0, AR0
	pshm	AR0	; push scale=0 onto stack
	ld		#data_addr, A	; A points to data loc
	
	call	_cfft1024
		
	mar		*AR7-	
	banz	minor_loop, *AR7	; see if we're done with this major frame

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

	ssbx	INTM			; Mask interrupts
	stm		#0FFh,IFR		; Clear any pending interrupts
	
	idle	3	; and now...we wait.
	
	; F7U12
; check for manual reset on int_3
;	ldm		IFR, A 	
;	stlm	A, AR0
;	bitf	AR0, #int_3
;	bc		read_init, TC
	
	ldm		BSPCE0, A ; store control extension register in AR6
	stlm	A, AR6

; otherwise, assume serial interrupt
	stm		#int_bx, IFR 	; clear int flag

	b		major_loop

;;
; Main acquisiton ('appcode') branch done
;;	

;;
; Interrupts
;;

timer_int:
	reted
	portw	0, wr_dog     ; Strobe the watchdog
; timer_int done

;	.include "serial_monitor.asm"
	.include "CFFT1024.ASM"
;	.include "LOG_10.ASM"
	.include "ad6620.asm"
