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

code_version		.string		"v0.3"
band_width			.string		"0300"

; Output constants

;output_scale_factor		.set	128		; 0 to 32767
output_shift_n		.set	8		; left shift before 8-bit mask
header_freq_mask	.set	0x0FFF	; defines bits of 32-bit major frame counter 
									; that must be zero for a header frame

; Run constants	
fft_scaling		.set	0		; 
;data_addr		.set	0x2000	; Where to store data for FFTing
data_n			.set	512	; Size of each FFT (# of IQ pairs)
data_discard	.set	512		; number of words to discard from Rx FIFO before taking data
data_minor_sz	.set	1 		; number of acquisitions per half-buffer interrupt
;abu_buff_loc	.set	0x0800	; serial buffer start location
;abu_buff_sz	.set	200		; size of serial buffer (2x major frame size IN BYTES)
fsync_sz		.set	4		; # of serial frame sync bytes (should be multiple of 4)
abu_buff_sz		.set	212		; size of serial buffer (2x major frame size IN BYTES)
		; should be set to 2*(transfer_table_sz + fsync_sz)

; Memory allocations
data_addr	.usect	".data_v", 0x800, 1, 1
scale_addr	.usect	".scale_v", 0x200, 1, 1
stackres	.usect	".stack_v", 0x40, 1, 1
abu_buff_loc	.usect	".sbuff_v", abu_buff_sz, 1, 1
abu_buff_hloc	.set	abu_buff_loc+abu_buff_sz/2	; half-way

; Memory pointers
iq_data		.set	data_addr	; 512 * 2 words * I/Q
fft_data	.set	data_addr	; 512 * 2 words * Re/Im
scale_data	.set	scale_addr	; 512 words
sqmag_data	.set	data_addr	; 512 * 2 words
sqsc_data	.set	data_addr+2*data_n	; 512 words
log_data	.set	data_addr 	; 512 * 2 words
power_data	.set	data_addr	; 512 words 
ebs_data	.set	data_addr+data_n	; 512 words

; mode flags
mode_std_bit	.set	0001b	; standard operations
mode_dbg_bit	.set	0010b	; debug

mode_std_n		.set	transfer_table_sz
mode_dbg_n		.set	512

; Scratchpad RAM usage
bridge_count	.set	scratch
minor_count	.set	scratch+1
bspce_save	.set	scratch+2
bridge_size	.set	scratch+3
mode_flag	.set	scratch+4
shb_addr	.set	scratch+5
major_count	.set	scratch+6	; two words!
nco_freq	.set	scratch+8	; two words!

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

	stm	#0FFh,IFR	; Clear any pending interrupts
	stm	#ntss,TCR	; Stop timer, if running
		
; Main data code start
read_init:
	call	rsp_reset
	nop
	nop		
	portw	AR0,wr_rs_rx	; Hardware reset of AD6620 RSP
	portw	AR0,wr_rs_rx	; Hardware reset of AD6620 RSP
	portw	AR0,wr_rs_rx	; Hardware reset of AD6620 RSP
	portw	AR0,wr_rs_rx	; Hardware reset of AD6620 RSP
	portw	AR0,wr_rs_rx	; Hardware reset of AD6620 RSP
	portw	AR0,wr_rs_rx	; Hardware reset of AD6620 RSP
	nop
	nop
	call	rsp_reset
	call	rsp_init
	call	rsp_clear
	call	rsp_mstart
	
	rpt		#4444	; Let the AD6620 do its first initialization in peace
	nop
	
	call	rsp_reset
	
	
	; store permanent NCO Frequency
	ld		#0x4420, A
	stl		A, @nco_freq
	ld		#0x01FA, A
	stl		A, @(nco_freq+1)


	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
	nop
	nop	

	stm	#lsb_sel, AR0	; Reset acq_seq
	portw	AR0, wr_disc
	nop
		
	; BSP prep

	stm		#(bspc_Free+bspc_fsm), BSPC0 		; reset BSP
	stm		#(int_bx), IMR			; unmask serial transmit interrupt
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx autobuffer
	stm		#(abu_buff_loc-0x800), AXR	; where in the 2048 words of buffer RAM 
							; does the transmit buffer start?
	stm		#(abu_buff_sz), BKX		; buffer size
	
; Clear entire serial buffer
	stm		#abu_buff_sz-1, BRC
	stm		#abu_buff_loc, AR4
	rptb	buff_init_loop - 1
	
	st		#0h, *AR4+
	
buff_init_loop:
	.global buff_init_loop, head_ramp, major_loop

; Write out header to first buffer half

	stm		#abu_buff_loc, AR4
	; two-byte frame sync 0xEB90
;	stm		#(abu_buff_loc+abu_buff_sz/2-2), AR4
	st		#0xFE, *AR4+	; 4-byte initialization sync
	st		#0x6B, *AR4+
	st		#0x28, *AR4+
	st		#0x40, *AR4+
	
	stm		#file_header, AR0	; Point to static header words
header_loop:
	ld		*AR0+, A		; Get a word, point to next
	bc		header_loop_x, AEQ		; If terminator, end static header
	stl		A, *AR4+		; Write to serial buffer
	b		header_loop
header_loop_x:


	ld		#abu_buff_loc, A
	ld		#(abu_buff_sz/2), B
	
	call	_serial_cook

; Set initial bspce_save such that the first acquisition will
; write to the second half of the serial buffer
	st		#bspce_xh, @bspce_save
		
; Start BSP transmits
	stm		#(bspc_Free + bspc_fsm + bspc_nXrst), BSPC0	; have to hold fsm bit

;	rsbx	INTM ; global interrupt enable

; All Aux Registers are fungible in the main loop: values which must be preserved
; over time are stored in the scratchpad RAM as defined above.  Note that only AR6
; and AR7 are required to be preserved by the DSP Library functions (and most others),
; all other ARx may be modified within function calls.

	ld		#0, A
	dst		A, @major_count

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
data_acq_start:

	st	#0, @bridge_count		; reset bridged data counter
	st	#0, @minor_count 	; set minor frame counter

	
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
	bitf	AR0, #rx_efo
	
	bc	discard_fifo_empty, NTC
	portr	rd_rx_out, AR1		; read data into AR1
	mar	*AR2-				; decrement word counter		
discard_fifo_empty:

	banz	rx_discard_loop, *AR2
	
	
; loop to read data from Rx FIFO into RAM
	stm	#2, AR0
	stm	#iq_data, AR1	; set address for first data word
	stm	#(data_n*2-1), AR2
pre_read:
	nop
rx_read_loop:
	; read only if rx fifo is nonempty
	portr	rd_disc, AR3
	nop
	nop
	bitf	AR3, #rx_efo
	
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

	ld	#iq_data, A
	ld	#data_n, B
	
	call	_hann_window

	.global	pre_bit_rev
pre_bit_rev:
	
; Bit reversal
	stm		#data_n, AR0
	pshm	AR0
	stm		#iq_data, AR0
	pshm	AR0
	ld		#iq_data, A
	
	call _cbrev32
	
	frame	2


	.global pre_fft
pre_fft:
	stm		#fft_scaling, AR0
	pshm	AR0
	ld		#fft_data, A
	
	call 	_cfft32_512
	
	frame	1

	
	.global	pre_move
pre_move:
; flip things into proper power spectra order (swap halves)
; remove zeroes here, too

	stm		#(data_n-1), BRC
	stm		#fft_data, AR2
	stm		#(fft_data + 2*data_n), AR3
	
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
	stm		#fft_data, AR0		; output
	pshm	AR0
	stm		#fft_data, AR0		; input
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
	stm		#fft_data, AR0
	rptb	abs_loop - 1
	
	dld		*AR0, A
	abs		A
	dst		A, *AR0+

abs_loop:


	.global	pre_sqmag, pre_log, pre_db
pre_sqmag:
; |FFT|^2
	ld		#sqmag_data, A
	ld		#data_n, B
	
	call	_sqmag




	.global pre_logps
pre_logps:
	
	stm		#scale_data, AR0	; scale saves
	pshm	AR0
	stm		#sqsc_data, AR0	; output
	pshm	AR0
	stm		#sqmag_data, AR0				; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_log_prescale
	
	frame	3


pre_scale:
	

pre_log:
; log_10(|FFT|^2) (outputs 32-bit Q16.15)

	stm		#data_n, AR0
	pshm	AR0
	stm		#log_data, AR0			; write to beginning of data buffer
	pshm	AR0
	ld		#sqsc_data, A	; read from halfway point of data buffer
	
	call _log_10

	frame	2


	.global pre_descale
pre_descale:

	stm		#scale_data, AR0	; scale saves
	pshm	AR0
	stm		#power_data, AR0		; output
	pshm	AR0
	stm		#log_data, AR0		; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_descale
	
	frame	3	; free stack


	.global post_descale
post_descale:
; multiply by output_scale_factor, shift right by output_shift_n, re-store

	pshm	ST0
	pshm	ST1
	ssbx	FRCT
	ssbx	SXM
	ssbx	OVM
	rsbx	C16

; Scale and shift, save 8-bit data

	stm		#data_n-1, BRC
	stm		#power_data, AR0
	stm		#(data_addr + 2*data_n), AR1
	stm		#ebs_data, AR2
;	stm		#output_scale_factor, T
	rptb	ebs_loop - 1
	
;	mpy		*AR0+, A	; multiply by scale factor in T
;	sfta	A, #0-output_shift_n
;	and		#0xFF0000, A
;	dst		A, *AR1+
	
;	mpy		*AR0+, A	; multiply by scale factor in T
	ld		*AR0+, A
	sfta	A, #0-output_shift_n
	add		#128, A
	and		#0xFF, A
	stl		A, *AR2+
;	dadd	output_shift_n, A	; shift
;	sat		A
;	and		#0xFF, #16, A			; mask to A(23-16)
;	sth		A, *AR2+				; store A(23-16)
	
ebs_loop:

	nop

	.global	dp_end
dp_end:

	stm		#data_n/2-1, BRC
	stm		#0, AR0
	stm		#ebs_data, AR2
	stm		#ebs_data+data_n-1, AR3
	rptb	dummy_data - 1
	
	mvkd	AR0, *AR2+
	mvkd	AR0, *AR3-
	mar		*AR0+
	
dummy_data:
	.global dummy_data

	popm	ST1
	popm	ST0

	nop

*
* End data processing, begin serial data handling
*

	stm		#(lsb_sel), AR0
	portw	AR0, wr_disc
	
; Standard mode (#buff_size bytes) or debug mode (#debug_size) depending on trm_28 state.
	portr	rd_disc, AR0	; Get discrete bits
	
;	stm		#0, AR0	; DEBUG !!
;	nop
;	nop
	
	bitf	AR0, #trm_28	; Test for high terminal input	
	bc		standard_mode, NTC	; If trm_28 is low (NTC), standard data settings
				; to #debug_size

	st	#mode_dbg_n, @bridge_size
	st	#mode_dbg_bit, @mode_flag
	
	b 	debug_mode_skip

standard_mode:

	st	#mode_std_n, @bridge_size
	st	#mode_std_bit, @mode_flag

debug_mode_skip:
	

	
; entry point for bridging data transfers over multiple serial half-buffers
bridge_data:
	stm		#(acq_test2+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc

	nop
	nop
	; Determine serial buffer position
	ld		#abu_buff_loc, A	; load buffer base
	
	bitf	@bspce_save, #bspce_xh 		; read XH out of stored BSPCE register
	nop
	nop
	bc		buff_skip, NTC ; if first half _finished_ (XH=0, NTC), do nothing
	
	add		#(abu_buff_sz/2), A
	
	stm		#(acq_test2+acq_test3+lsb_sel), AR0
	portw	AR0, wr_disc
	
buff_skip:
	nop
	nop
	stl 	A, @shb_addr	; scratch storage for serial half-buffer address
	nop
	nop

abu_first_half:
	.global abu_first_half

	ssbx	INTM
	
; Clear serial buffer half
	mvdm	@shb_addr, AR4
	nop
	rpt		#(abu_buff_sz/2-1)
	st		#0xFF, *AR4+
	
	; reset AR4 for data copy
	mvdm	@shb_addr, AR4
	nop
	nop
	
abu_fill_start:
	.global abu_fill_start
		
	; two-byte frame sync 0xEB90
	st		#0xEB, *AR4+
	st		#0x90, *AR4+

	; two-byte infofoop
	ld		@minor_count, A				; byte 1, minor frame number
	and		#0xFF, A
	stl		A, *AR4+
	dld		@major_count, A				; byte 2, major frame number
	and		#0xFF, A, B
	stl		B, *AR4+

post_sync_write:
	.global post_sync_write

; Transfer in selected data mode

	bitf	@mode_flag, #mode_dbg_bit
	bc		dbg_transfer, TC
	
	; in standard mode, check if 8-bit major_count (still in A) == 0,
	; if so, transfer a header instead of data
	
; Std header: spit out a header frame every 4096th
	and		#header_freq_mask, A
	bc		header_skip, ANEQ	; A != 0, skip header
	
	call	hwrite
	st		#mode_std_n, @bridge_count	; fake it out
	nop
	nop
	
	b		end_transfer
	
header_skip:
; Std transfer: selected bins in a 1-frame major frame
	; transfer selected data to serial buffer
	ld		#ebs_data, A	; input addr in A
	ldm		AR4, B			; output addr in B
	
	call	transfer
	
	st		#mode_std_n, @bridge_count	; fake it out
	
	b		end_transfer

; Debug transfer: entire 512-bin fft spread over multiple minor frames
dbg_transfer:

	; copy raw data (words) into serial buffer (bytes)
	ld		#ebs_data, A
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
	cmpr	LT, AR1				; If we're not done with a bridged data sequence, 
	nop
	nop
	xc		2, NTC
	rsbx	BRAF
	nop
	nop
	nop
	nop
	nop
	nop
	.global rawdata_loop, dbg_transfer_skip
rawdata_loop:
	
	mvmd	AR1, @bridge_count
	nop
	
end_transfer:
	.global	end_transfer

	nop

	
serial_transfer_end:
	.global serial_transfer_end
	
	nop
	
	
; Bit reverse and add start/stop bits
	ld		@shb_addr, A
	ld		#(abu_buff_sz/2), B

	call	_serial_cook
	

;	rsbx	INTM
		
	addm	#1, @minor_count
		
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
	
	stm		#(acq_test4+lsb_sel), AR0
	portw	AR0, wr_disc

	ssbx	INTM
	stm		#0FFh,IFR		; Clear any pending interrupts
	
	idle	2	; and now...we wait.

	.global post_sleep
post_sleep:
	
; check for aux int -> serial monitor
;	bitf	IFR, #int_3
;	cc		inth_3, TC
	
; make sure we had a serial interrupt
	bitf	IFR, #int_bx
	bc		pre_sleep, NTC	; stray interrupt, go back to IDLE
	
	nop
		
	stm		#int_bx, IFR 	; clear int flag
	
	mvmd	BSPCE0, @bspce_save ; store control extension register in AR6

	bitf	BSPCE0, #bspce_xh
	bc		xh_skip, NTC

	stm		#(lsb_sel), AR0
	portw	AR0, wr_disc
	
xh_skip:

	rpt		#100
	nop
	
	stm		#lsb_sel, AR0
	portw	AR0, wr_disc
	
	mvdm	@bridge_size, AR0	; need to copy these 
	mvdm	@bridge_count, AR1	; to use CMPR
	nop
	nop
	cmpr	LT, AR1				; If we're not done with a bridged data sequence, 
	bc		bridge_data, TC	; jump to bridge_data to continue transfers, otherwise...

	dld		@major_count, A	; increment major frame counter
	add		#1, A
	dst		A, @major_count
	
	b		major_loop		; new data acquisition

;;
; Main acquisiton ('appcode') branch done
;;	

;;
; Interrupts
;;

; Non-Maskable Interrupt
; 		this is hit by the watchdog
int_nmi:
	nop
	nop
		
	stm		#0, AR0
	portw	AR0,wr_dog	; Strobe watchdog timer
	
	b		0xF800
	
; Setup: IPTR=0x1FF, OVLY=1, all else =0
; This should set things up to completely reload the program from the EPROM on reset
	stm		#0xFFA0, PMST
	nop
	nop

;	reset	; I don't have to take this.  ...I'm going home.
	
	ret		; should never get here!

inth_3:
	ssbx	INTM
	stm		#int_3, IFR 	; clear int flag

	; call serial monitor

	
;	calld	_RxDSP_Monitor
;	stm		#bspce_haltx, BSPCE	 ; tell serial transmit to halt after completing this half-buffer

	
	retd
	nop
	nop

file_header:
	.string	"Dartmouth College Rx-DSP, AGO Site 3 Unit 0."
	.word	0000h	; Null terminator

****
* hwrite
*
* Writes a header:
*
* <0xFE6B2840><RxDSP><Unit #><Ver #><NCOF><MFCB><00000000>
*
****

hwrite:
	.global	hwrite

	pshm	AR3

; 4-byte sync
	stm		#static_header, AR3	; Point to static header words
	rpt		#static_header_len		; <SYNC><RxDSP>
	mvdd	*AR3+, *AR4+
	
	stm		#code_version, AR3
	rpt		#3
	mvdd	*AR3+, *AR4+
	
	stm		#spec_header, AR3	; Point to static header words
	rpt		#spec_header_len		; <skipNS><fbstFBSN><fbenFBEN>
	mvdd	*AR3+, *AR4+
	
	stm		nco_freq, AR3
	ld		*AR3, #-8, A
	and		#0xFF, A
	stl		A, *AR4+
	ld		*AR3+, A	; inc to second word
	and		#0xFF, A
	stl		A, *AR4+
	ld		*AR3, #-8, A
	and		#0xFF, A
	stl		A, *AR4+
	ld		*AR3, A
	and		#0xFF, A
	stl		A, *AR4+
		
	stm		#band_width, AR3
	rpt		#3
	mvdd	*AR3+, *AR4+

	stm		major_count, AR3
	ld		*AR3, #-8, A
	and		#0xFF, A
	stl		A, *AR4+
	ld		*AR3+, A	; inc to second word
	and		#0xFF, A
	stl		A, *AR4+
	ld		*AR3, #-8, A
	and		#0xFF, A
	stl		A, *AR4+
	ld		*AR3, A
	and		#0xFF, A
	stl		A, *AR4+
		
	popm	AR3
	
	retd
	nop
	nop

static_header:
		.word	0xFE, 0x6B, 0x28, 0x40
		.string	"AGORxDSP"	; 12 bytes
static_header_end:
static_header_len	.set	static_header_end-static_header-1

spec_header:
		.string	"stride08"
		.string "cbst0249"
		.string	"cben0262"
		.string	"00000000"	; pad to 32 bytes
spec_header_end:
spec_header_len		.set	spec_header_end-spec_header-1
	

;	.include "ad6620.asm"
;	.include "cbrev.asm"

	.end