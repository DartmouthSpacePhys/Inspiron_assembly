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
	.ref	_cbrev32, _cfft32_512, _log_10, _hann_window, _sqmag, _serial_cook
	.ref	_log_prescale, _sqmag_prescale, _descale
	.ref	rsp_clear, rsp_reset, rsp_init, rsp_mstart, rsp_sstart
;	.ref	ad6620_soft_reset, ad6620_filter, ad6620_master_run, rsp_setup
	.ref	transfer, transfer_table_sz
	.global bridge_data, buff_clear_loop
	.def	ago_main, int_nmi
	
	.include "rx-dsp.h"
;	.include "int_table.h"
	.text

; Output constants

output_scale_factor		.set	128		; 0 to 32767
output_shift_n			.set	0		; 0 to 7 (don't want the sign bit)

; Run constants	
fft_scaling		.set	0		; 
;data_addr		.set	0x2000	; Where to store data for FFTing
data_n		.set	512	; Size of each FFT (# of IQ pairs)
data_discard	.set	512		; number of words to discard from Rx FIFO before taking data
data_minor_sz	.set	1 		; number of acquisitions per half-buffer interrupt
;abu_buff_loc	.set	0x0800	; serial buffer start location
abu_buff_sz		.set	0x0400	; size of serial buffer (2x major frame size IN BYTES)
fsync_sz		.set	4		; # of serial frame sync bytes (should be multiple of 4)

; Memory allocations
data_addr	.usect	".data_v", 0x800, 1, 1
scale_addr	.usect	".scale_v", 0x200, 1, 1
stackres	.usect	".stack_v", 0x40, 1, 1
abu_buff_loc	.usect	".sbuff_v", abu_buff_sz, 1, 1
abu_buff_hloc	.set	abu_buff_loc+abu_buff_sz/2	; half-way

; mode flags
mode_std_bit	.set	0001b	; standard operations
mode_dbg_bit	.set	0010b	; debug

mode_std_n		.set	transfer_table_sz
mode_dbg_n		.set	490

; Scratchpad RAM usage
bridge_count	.set	scratch
minor_count	.set	scratch+1
bspce_save	.set	scratch+2
bridge_size	.set	scratch+3
mode_flag	.set	scratch+4
ebs_max		.set	scratch+5
ebs_min		.set	scratch+6

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
	
	frame	2


	.global pre_fft
pre_fft:
	stm		#fft_scaling, AR0
	pshm	AR0
	ld		#data_addr, A
	
	call 	_cfft32_512
	
	frame	1

	
	.global	pre_move
pre_move:
; flip things into proper power spectra order (swap halves)
; remove zeroes here, too

	stm		#(data_n-1), BRC
	stm		#data_addr, AR2
	stm		#(data_addr + 2*data_n), AR3
	
	rptb	move_loop - 1

	dld		*AR2, A
	dld		*AR3, B
	
	nop
	nop
	xc		2, AEQ
	add		#1, A
	xc		2, BEQ
	add		#1, B
	
	dst		A, *AR3+
	dst		B, *AR2+	
	
move_loop:
	

	.global	pre_sqscale
pre_sqscale:

	stm		#scale_addr, AR0	; scale saves
	pshm	AR0
	stm		#data_addr, AR0		; output
	pshm	AR0
	stm		#data_addr, AR0		; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_sqmag_prescale
	
	frame	3	; free stack


	.global pre_abs
pre_abs:
	ssbx	SXM
	ssbx	OVM
	nop
	nop

	stm		#(2*data_n-1), BRC
	stm		#data_addr, AR0
	rptb	abs_loop - 1
	
	dld		*AR0, A
	abs		A
	dst		A, *AR0+

abs_loop:


	.global	pre_sqmag, pre_log, pre_db
pre_sqmag:
; |FFT|^2
	ld		#data_addr, A
	ld		#data_n, B
	
	call	_sqmag




	.global pre_logps
pre_logps:
	
	stm		#(data_addr+3*data_n), AR0	; scale saves
	pshm	AR0
	stm		#(data_addr+2*data_n), AR0	; output
	pshm	AR0
	stm		#data_addr, AR0				; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_log_prescale
	
	frame	3


pre_scale:
	

pre_log:
; log_10(|FFT|^2) (outputs 32-bit Q16.15)

	stm		#data_n, AR0
	pshm	AR0
	stm		#data_addr, AR0			; write to beginning of data buffer
	pshm	AR0
	ld		#(data_addr+2*data_n), A	; read from halfway point of data buffer
	
	call _log_10

	frame	2


	.global pre_ebs
pre_ebs:

	stm		#scale_addr, AR0	; scale saves
	pshm	AR0
	stm		#data_addr, AR0		; output
	pshm	AR0
	stm		#data_addr, AR0		; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_descale
	
	frame	3	; free stack


	.global post_ebs
post_ebs:
; multiply by output_scale_factor, shift right by output_shift_n, re-store

	pshm	ST0
	pshm	ST1
	ssbx	FRCT
	ssbx	SXM
	ssbx	OVM
	rsbx	C16

; find maximum data value

	stm		#data_n-2, BRC
	stm		#data_addr, AR0
	rptbd	max_loop - 1
	ld		*AR0+, A
	nop
	
	ld		*AR0+, B
	max		A
	
max_loop:

	stl		A, @ebs_max
	
; find minimum data value

	stm		#data_n-2, BRC
	stm		#data_addr, AR0
	rptbd	min_loop - 1
	ld		*AR0+, A
	nop
	
	ld		*AR0+, B
	min		A
	
min_loop:

	add		@ebs_max, A		; min+max
	sfta	A, #-1 			; div by 2
	
; center the power spectrum

	stm		#data_n-1, BRC
	stm		#data_addr, AR0
	rptb	center_loop - 1
	
	ld		*AR0, B
	sub		A, B
	stl		B, *AR0+
	
center_loop:
	.global centered
centered:

	stm		#data_n-1, BRC
	stm		#data_addr, AR0
	stm		#(data_addr + 2*data_n), AR1
	stm		#(data_addr + data_n), AR2
	stm		#output_scale_factor, T
	rptb	ebs_loop - 1
	
	mpy		*AR0+, A
;	sfta	A, #0-output_shift_n
;	and		#0xFF0000, A
	dst		A, *AR1+
	
	sfta	A, #0-output_shift_n
	and		#0xFF, #16, A
	sth		A, *AR2+
	
ebs_loop:

	nop

	.global	dp_end
dp_end:

	popm	ST1
	popm	ST0

	nop

*
* End data processing, begin serial data handling
*

; Standard mode (#buff_size bytes) or debug mode (#debug_size) depending on trm_28 state.
	portr	rd_disc, AR0	; Get discrete bits
	bitf	AR0,trm_28	; Test for high terminal input	
	bc		standard_mode, NTC	; If trm_28 is low (NTC), standard data settings
				; to #debug_size

	st	#508, @bridge_size
	st	#mode_dbg_bit, @mode_flag
	
	b 	debug_mode_skip

standard_mode:

	st	#mode_std_n, @bridge_size
	st	#mode_std_bit, @mode_flag

debug_mode_skip:
	

	
; entry point for bridging data transfers over multiple serial half-buffers
bridge_data:
	stm		#(acq_seq_out+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc

	nop
	nop
	; Determine serial buffer position
	stm		#abu_buff_loc, AR3	; load buffer base
	
	bitf	@bspce_save, #bspce_xh 		; read XH out of stored BSPCE register
	nop
	nop
	xc		2, TC ; if first half _finished_ (XH=0, NTC), do nothing
	addm	#(abu_buff_sz/2), @AR3
	nop
	nop
	nop
	nop

abu_first_half:
	.global abu_first_half

	ssbx	INTM
	
; Clear serial buffer half
	mvmm	AR3, AR4
	nop
	rpt		#(abu_buff_sz/2-1)
	st		#0x00, *AR4+
	
	
	; reset AR4 for data copy
	mvmm	AR3, AR4
	nop
	nop
	
abu_fill_start:
	.global abu_fill_start
		
	; four-byte frame sync 0xFE6B2840
	ld		#0xFE, A
	stl		A, *AR4+
	ld		#0x6B, A
	stl		A, *AR4+
	ld		#0x28, A
	stl		A, *AR4+
	ld		#0x40, A
	stl		A, *AR4+


	bitf	@mode_flag, #mode_dbg_bit
	bc		dbg_transfer_skip, TC
	
	; in standard mode, transfer selected data to serial buffer
	ld		#data_addr, A
	ld		#data_addr, B
	
	call	transfer

dbg_transfer_skip:

	; copy raw data (words) into serial buffer (bytes)
	ld		#(data_addr+data_n), A
	add		@bridge_count, A
	stlm	A, AR2
	
	mvdm	@bridge_size, AR0	; goal bridge size
	mvdm	@bridge_count, AR1	; current count

	stm		#((abu_buff_sz/2-fsync_sz)-1), BRC
	rptb	rawdata_loop - 1
	
;	ld		*AR2+, A		; load (data word) to Acc
;	and		#0xFF, A	; mask to low-byte
;	stl		A, *AR4+	; save to serial buffer

	mvdd	*AR2+, *AR4+
	
	mar		*AR1+
	nop
	nop
	cmpr	LT, AR1				; If we're not done with a bridged data sequence, 
	bc		rawdata_bskip, TC

	rsbx	BRAF
	nop
	nop
	nop
	nop
		
rawdata_bskip:

	nop
	nop
	.global rawdata_loop, dbg_transfer_skip
rawdata_loop:

	nop
	nop
	
	mvmd	AR1, @bridge_count


; Bit reverse and add start/stop bits
	ldm		AR3, A
	ld		#(abu_buff_sz/2), B

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

	.global pre_sleep
pre_sleep:
	
	ssbx	INTM
	stm		#0FFh,IFR		; Clear any pending interrupts
	
	idle	3	; and now...we wait.

	.global post_sleep
post_sleep:
	
; check for aux int -> serial monitor
;	bitf	IFR, #int_3
;	cc		inth_3, TC
	
; make sure we had a serial interrupt
;	bitf	IFR, #int_bx
;	bc		pre_sleep, NTC	; stray interrupt, go back to IDLE
	
	nop
		
	stm		#int_bx, IFR 	; clear int flag
	
	mvmd	BSPCE0, @bspce_save ; store control extension register in AR6
	
	mvdm	@bridge_size, AR0	; need to copy these 
	mvdm	@bridge_count, AR1	; to use CMPR
	nop
	nop
	cmpr	LT, AR1				; If we're not done with a bridged data sequence, 
	bc		bridge_data, TC	; jump to bridge_data to continue transfers, otherwise...

	b		major_loop		; new data acquisition

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