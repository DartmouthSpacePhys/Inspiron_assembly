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
;	.ref	_RxDSP_Monitor
	.ref	_cbrev32, _cfft32_512, _log_10, _hann_window, _dp_sqmag, _serial_cook
	.ref	rsp_clear, rsp_reset, rsp_init, rsp_mstart, rsp_sstart
;	.ref	ad6620_soft_reset, ad6620_filter, ad6620_master_run, rsp_setup
	.ref	transfer
	.global bridge_data, buff_clear_loop
	.def	ago_main, int_nmi
	
	.include "rx-dsp.h"
;	.include "int_table.h"
	.text

; Run constants	
fft_scaling		.set	0		; 
;data_addr		.set	0x2000	; Where to store data for FFTing
data_addr	.usect	".data_v", 0x800, 1, 1
stackres	.usect	".stack_v", 0x40, 1, 1
data_n		.set	512	; Size of each FFT (# of IQ pairs)
data_discard	.set	512		; number of words to discard from Rx FIFO before taking data
data_minor_sz	.set	1 		; number of acquisitions per half-buffer interrupt
abu_buff_loc	.usect	".sbuff_v", 0x400, 1, 1
;abu_buff_loc	.set	0x0800	; serial buffer start location
abu_buff_hloc	.set	abu_buff_loc+0x200	; half-way
abu_buff_sz		.set	1024	; size of serial buffer (2x major frame size IN BYTES)
fsync_sz		.set	4		; # of serial frame sync bytes (should be multiple of 4)
bridge_def_sz		.set	2048	;

; Scratchpad RAM usage
bridge_count	.set	scratch
minor_count	.set	scratch+1
bspce_save	.set	scratch+2
bridge_size	.set	scratch+3

        .bss TempLmem,1*2,0,0  ;temporary dword


RXDSP_START
ago_main:

	rsbx	XF

; Processor setup
	ssbx    INTM		; Disable interrupts 
	stm	#(stackres+0x40), SP	; set Stack Pointer
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
	call	rsp_reset
	call	rsp_init
	call	rsp_clear
	call	rsp_mstart
	
	rpt		#4444	; Let the AD6620 do its first initialization in peace
	nop
	
	call	rsp_reset
	
	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
	nop
	nop	

	stm	#lsb_sel, AR0	; Reset acq_seq
	portw	AR0, wr_disc
	nop
	
	; BSP prep

	stm		#(bspc_fsm), BSPC0 		; reset BSP
	stm		#(int_bx), IMR			; unmask serial transmit interrupt
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx autobuffer
	stm		#(abu_buff_loc-0x800), AXR	; where in the 2048 words of buffer RAM 
							; does the transmit buffer start?
	stm		#(abu_buff_sz), BKX		; buffer size
	
; Clear entire serial buffer
	stm		#abu_buff_loc, AR4
	stm		#abu_buff_sz-1, BRC
	rptb	buff_init_loop - 1
	
	st		#3FFh, *AR4+
	.global buff_init_loop, head_ramp, major_loop
buff_init_loop:


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

; Set initial bspce_save such that the first acquisition will
; write to the second half of the serial buffer
	st		#bspce_xh, @bspce_save
		
; Start BSP transmits
	stm		#(bspc_fsm + bspc_nXrst), BSPC0	; have to hold fsm bit

;	rsbx	INTM ; global interrupt enable

; All Aux Registers are fungible in the main loop: values which must be preserved
; over time are stored in the scratchpad RAM as defined above.  Note that only AR6
; and AR7 are required to be preserved by the DSP Library functions (and most others),
; all other ARx may be modified within function calls.

major_loop:
	
	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
	nop
	nop
		
	stm	#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc
	
	call	rsp_clear	; clear NCO RAM
	call	rsp_mstart	; and start digitizing	
	
;
; Reads
;
	st	#0, @bridge_count		; reset bridged data counter
	st	#bridge_def_sz, @bridge_size
	st	#data_minor_sz, @minor_count 	; set minor frame counter
minor_loop:

;
; Set wait states for Rx FIFO
;
	ldm	SWWSR, A
	ld	#65535, B
	xor	#7, #swwsr_is, B ; (0b111<<Nset XOR 0d65535) creates bitmask
	and	B, A			 ; mask out bits of interest
	or	#0, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
	; Nwait = 0 means no additional waits
	stlm	A, SWWSR

	ssbx	XF
	rpt #100
	nop
	rsbx	XF
	
	
	.global	pre_disc, pre_read
pre_disc:

; loop to read and discard first data out of AD6620
	stm		#(data_discard), AR2
	nop
rx_discard_loop:
	; read only if rx fifo is nonempty
	portr	rd_disc, AR0
	nop
	nop
	bitf	AR0, rx_efo
	
	bc	discard_fifo_empty, NTC
	portr	rd_rx_out, AR1		; read data into AR1
	mar	*AR2-				; decrement word counter		
discard_fifo_empty:

	banz	rx_discard_loop, *AR2
	
	
; loop to read data from Rx FIFO into RAM
	stm	#2, AR0
	stm	#data_addr, AR1	; set address for first data word
	stm	#(data_n*2-1), AR2
pre_read:
	nop
rx_read_loop:
	; read only if rx fifo is nonempty
	portr	rd_disc, AR3
	nop
	nop
	bitf	AR3, rx_efo
	
	bc	read_fifo_empty, NTC
	
	portr	rd_rx_out, *AR1+
	st	#0, *AR1+		; zero out second word
	mar	*AR2-			; decrement word counter
	
read_fifo_empty:

	banzd	rx_read_loop, *AR2
	nop
	nop
	
;
; Set wait states for other stuff (full 7)
;
	ldm	SWWSR, A
	or	#7, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
	stlm	A, SWWSR
	nop
	nop
	
	ssbx	XF
	rpt #50
	nop
	rsbx	XF
	
*
* End data acquisition, begin data processing
*
 
data_process:


	.global pre_window
pre_window:

	ld	#data_addr, A
	ld	#data_n, B
	
	call	_hann_window

	.global	pre_bit_rev
pre_bit_rev:
	
; Bit reversal
	stm		#data_n, AR0
	pshm	AR0
	stm		#data_addr, AR0
	pshm	AR0
	ld		#data_addr, A
	
	call _cbrev32
	
	nop
	nop

	.global pre_fft
pre_fft:
	
	
	stm		#fft_scaling, AR0
	pshm	AR0
	ld		#data_addr, A
	
	call _cfft32_512

	.global	pre_sqmag, pre_log, pre_db
pre_sqmag:
; |FFT|^2
	ld		#data_addr, A
	ld		#data_n, B
	
	call	_dp_sqmag

; move sqmag data to second half of data buffer so log_10 doesn't eat it
; while we're at it, flip order to get a proper power spectra

	.global pre_move
pre_move:
	stm		#(data_addr + data_n/2), AR2
	stm		#(data_addr + data_n), AR3
	rpt		#(data_n/2-1)
	mvdd	*AR2+, *AR3+
	stm		#data_addr, AR2	
	rpt		#(data_n/2-1)
	mvdd	*AR2+, *AR3+

pre_log:
; log_10(|FFT|^2) (outputs 32-bit floats)

	stm		#data_n, AR1
	pshm	AR1
	stm		#data_addr, AR1			; write to beginning of data buffer
	pshm	AR1
	ld		#(data_addr+data_n), A	; read from halfway point of data buffer
	
	call _log_10

pre_db:
; 10*log_10(|FFT|^2)
	ssbx	SXM
		
	stm		#data_n - 1, BRC
	stm		#(data_addr + data_n), AR1
	rptb	db_loop - 1
	
	mpy		*AR1, #10, A
	stl		A, *AR1+
	
db_loop:
	rsbx	SXM	

*
* End data processing, begin serial data handling
*

; Standard mode (#buff_size bytes) or debug mode (#debug_size) depending on trm_28 state.
	portr	rd_disc, AR0	; Get discrete bits
	bitf	AR0,trm_28	; Test for high terminal input	
	xc	2,TC	; If trm_28 is high (enabled, TC), set @bridge_size 
				; to #debug_size
	st	#data_n, @bridge_size
	
; entry point for bridging data transfers over multiple serial half-buffers
bridge_data:
	stm		#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc

	nop
	nop
	; Determine serial buffer position
	stm		#abu_buff_loc, AR0	; load buffer base
	
	bitf	@bspce_save, #bspce_xh 		; read XH out of stored BSPCE register
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


; Bit reverse and add start/stop bits
	ldm	AR0, A
	ld	#(abu_buff_sz/2), B

	call	_serial_cook
	

;	rsbx	INTM
		

		
; If a major frame is complete, shut it down

; unset acq_seq, keep lsb_sel
	stm		#lsb_sel, AR0
	portw	AR0, wr_disc

; Strobe watchdog- once per acquisition
	stm		#0, AR0        ; Data is not used- just the wr_dog strobe
	portw	AR0,wr_dog     ; Strobe the watchdog

; Stop acquisition, clear interrupts, then idle until an interrupt.
	call	rsp_reset

	nop
	nop

pre_sleep:
	
	ssbx	INTM
	stm		#0FFh,IFR		; Clear any pending interrupts
	
	idle	3	; and now...we wait.
	
; check for aux int -> serial monitor
;	bitf	IFR, #int_3
;	cc		inth_3, TC
	
; make sure we had a serial interrupt
;	bitf	IFR, #int_bx
;	bc		pre_sleep, NTC	; stray interrupt, go back to IDLE
	
	nop
		
	stm		#int_bx, IFR 	; clear int flag
	
	mvmd	BSPCE0, @bspce_save ; store control extension register in AR6
	
	cmpm	@bridge_count, #bridge_def_sz		; If we're not done with a bridged data sequence, 
	bc		bridge_data, NTC	; jump to bridge_data to continue transfers, otherwise...

	b		major_loop

;;
; Main acquisiton ('appcode') branch done
;;	

;;
; Interrupts
;;

int_nmi:
	nop
	nop
	
	ssbx	XF
	rpt		#30000
	nop
	rsbx	XF
	
	nop
	nop
	
	ret

inth_3:
	ssbx	INTM
	stm		#int_3, IFR 	; clear int flag

	; call serial monitor

	
;	calld	_RxDSP_Monitor
;	stm		#bspce_haltx, BSPCE	 ; tell serial transmit to halt after completing this half-buffer

	
	retd
	nop
	nop

static_header:
	.pstring	"Dartmouth College Rx-DSP, AGO Unit T, test v3"
	.word	0000h	; Null terminator
	

;	.include "ad6620.asm"
;	.include "cbrev.asm"

	.end