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
	.ref	_serial_cook
	.ref	rsp_clear, rsp_reset, rsp_init, rsp_mstart, rsp_sstart, rsp_freq
;	.ref	ad6620_soft_reset, ad6620_filter, ad6620_master_run, rsp_setup
	.ref	transfer, transfer_table_sz
	.global bridge_data, buff_clear_loop
	.def	ago_main, int_nmi
	
	.include "rx-dsp.h"
;	.include "int_table.h"
	.text

find_me				.ulong		0x6B28FE40
unit_designation	.uword		0	; Unit number (Master = 0)
code_version		.string		"v1.0"
station_code		.string		"SS"

band_width			.string		"0750"

; Rotating center frequency table
; 	32-bit values derived by mapping the sampling frequency (S) to the 0:2^32 range,
;	then taking the ratio of center frequency (C) to S, i.e. C/S*2^32

cfreq_table:
		.word	0x01d2, 0xf1c9	;  475 KHz
		.word	0x04b4, 0x39a7	; 1225 KHz
		.word	0x0795, 0x8185	; 1975 KHz
		.word	0x0a76, 0xc964	; 2725 KHz
cfreq_table_end:
cfreq_table_sz	.set	cfreq_table_end-cfreq_table

cfreq_test1		.set	0x0e66
cfreq_test2		.set	0x6758	; 3750 KHz

; Run constants	
data_n			.set	512	; Size of each FFT (# of IQ pairs)
data_discard	.set	512		; number of words to discard from Rx FIFO before taking data
data_minor_sz	.set	1 		; number of acquisitions per half-buffer interrupt
abu_buff_sz		.set	1048	; size of serial buffer (2x major frame size IN BYTES)
fsync_sz		.set	4		; # of serial frame sync bytes (should be multiple of 4)

; Memory allocations
data_addr		.usect	".data_v", 0x800, 1, 1
stackres		.usect	".stack_v", 0x40, 1, 1
abu_buff_loc	.usect	".sbuff_v", abu_buff_sz, 1, 1
abu_buff_hloc	.set	abu_buff_loc+abu_buff_sz/2	; half-way

; Scratchpad RAM usage
bridge_count	.set	scratch
minor_count		.set	scratch+1
bspce_save		.set	scratch+2
bridge_size		.set	scratch+3
major_count		.set	scratch+4	; two words!
nco_freq		.set	scratch+6	; two words!
cfreq_tp		.set	scratch+8

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
	
	ssbx	XF
	rpt		#64
	nop
	rsbx	XF
 
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
	.global read_init
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
	

	; TSP shutoff
	
;	stm		#(tspc_Free+tspc_fsm+tspc_nXrst+tspc_nRrst), TSPC
	stm		#(tspc_Free+tspc_fsm), TSPC
	
	; BSP prep

	stm		#(bspc_Free+bspc_fsm), BSPC0 		; reset BSP
	stm		#(int_bx), IMR			; unmask serial transmit interrupt
	stm		#(bspce_fe+bspce_bxe+bspce_haltx), BSPCE0	; 10-bit words, enable tx autobuffer, halt after first half-buffer
	stm		#(abu_buff_loc-0x800), AXR	; where in the 2048 words of buffer RAM 
							; does the transmit buffer start?
	stm		#(abu_buff_sz), BKX		; buffer size
	
; Clear entire serial buffer
	stm		#abu_buff_loc, AR4
	stm		#abu_buff_sz-1, BRC
	rptb	buff_init_loop - 1
	
	st		#0h, *AR4+
	.global buff_init_loop, head_ramp, major_loop
buff_init_loop:

; set initial frequency table position

	st		#cfreq_table_sz-2, @cfreq_tp


;	rsbx	INTM ; global interrupt enable

; All Aux Registers are fungible in the main loop: values which must be preserved
; over time are stored in the scratchpad RAM as defined above.  Note that only AR6
; and AR7 are required to be preserved by the DSP Library functions (and most others),
; all other ARx may be modified within function calls.

	ld		#0, A
	dst		A, @major_count
	
; Set initial bspce_save such that the first acquisition will
; write to the second half of the serial buffer
	st		#bspce_xh, @bspce_save
		
	; boot lag: insert >50 ms delay to allow everyone plenty of time to boot up
	stm		#511, BRC
	nop
	nop
	rptbd	boot_delay_loop - 1
	nop
	nop
	
	nop
	
	rpt		#4096
	nop
	
	nop
	nop	
	
boot_delay_loop:

	nop
	nop
	
	; now synchronize units for the first time
	call	sync_units

	; Start BSP transmits
	stm		#(bspc_Free + bspc_fsm + bspc_nXrst), BSPC0	; have to hold fsm bit
	nop
	nop
	
****
* Main loop
****

major_loop:
	.global	major_loop
	
	; Method:
	;
	; Master waits for acq_seq_rdy from Slaves, then raises acq_seq_out, starting synced
	; acquisition.  Note any previous acquisition will still be transferring its last
	; half-buffer, and the ABU will be set to halt transmissions when that half is done.
	; The acq_seq_rdy & out lines are both held high on All, until the end of this new 
	; acquisition and half-buffer fill.  Then Master waits for its own ABU haltx, and 
	; then for !acq_seq_rdy (signaling Slaves have hit ABU haltx), before dropping 
	; acq_seq_out, signaling time for the next synchronized ABU startup.

;	call	cfreq_walk
	
	; acquisition sync
	call	sync_units
		
	portr	rs_rx_fifo, AR0    ; Reset Rx FIFO - also sent by wire to Slave
		
;	dld		#
	
	cmpm	*(unit_designation), #0
	bc		slave_startup, NTC
	
	; if Master (unit 0) insert delay time to allow
	; Slaves time to detect acq_seq_out and start up
	rpt		#128
	nop
	
	call	rsp_mstart	; start digitizing as Master
	
	b		data_acq_start
	
slave_startup:

	call	rsp_sstart 	; start digitizing as Slave

	
;
; Reads
;
data_acq_start:

	st	#0, @bridge_count	; reset bridged data counter
	st	#0, @minor_count 	; reset minor frame counter

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
	
; Stop acquisition
	call	rsp_reset

	; drop acq flags
	stm		#lsb_sel, AR0
	portw	AR0, wr_disc
	
*
* End data collection, begin serial data handling
*

	st	#4*data_n, @bridge_size

; entry point for bridging data transfers over multiple serial half-buffers
bridge_data:
	.global	bridge_data

	stm		#(acq_test5+lsb_sel), AR0 ; send acq_seq, set lsb_sel
	portw	AR0, wr_disc

	nop
	nop
	; Determine serial buffer position
	stm		#abu_buff_loc, AR3	; load buffer base
	
	bitf	@bspce_save, #bspce_xh 		; read XH out of stored BSPCE register
	nop
	nop
	bc		buff_skip, NTC	; if first half _finished_ (XH=0, NTC), do nothing
	
	addm	#(abu_buff_sz/2), @AR3
	stm		#(acq_test3+lsb_sel), AR0
	portw	AR0, wr_disc

buff_skip:
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


	; two-byte frame sync 0xEB90
	st		#0xEB, *AR4+
	st		#0x90, *AR4+

	; two-byte infofoop
	ld		*(unit_designation), #6, A	; byte 1, 2 MSB, unit number
	or		@minor_count, A				; byte 1, 6 LSB, minor frame number
	stl		A, *AR4+
	dld		@major_count, A				; byte 2, 8 bit, major frame number
	and		#0xFF, A
	stl		A, *AR4+

dinner_is_ready:
	.global dinner_is_ready
	

	ld		#((abu_buff_sz/2-fsync_sz)/2-1), B	; let's stick the BRC value here...
	
	; If haltx is true, we are starting a new major frame, so write the header
	bitf	BSPCE0, #bspce_haltx
	bc		header_skip, NTC
	
	call	hwrite	; write out header, uses & modified write address in AR4
	sub		#16, B	; oops, 32 bytes less space in this half buffer

header_skip:
	
				
	; copy raw data (words) into serial buffer (bytes)
	ld		#data_addr, A
	add		@bridge_count, #-1, A	; div by 2 to increment input word-wise
	stlm	A, AR2
	stlm	B, BRC	; and here's our BRC setup
	
	mvdm	@bridge_size, AR0	; goal bridge size
	mvdm	@bridge_count, AR1	; current count
	
	rptb	rawdata_loop - 1

	ld		*AR2, -8, A	; load (data word) >> 8 to Acc
	and		#0xFF, A	; mask to low-byte
	stl		A, *AR4+	; save to serial buffer
	mar		*AR1+		; count bytes
	
	ld		*AR2+, A 	; reload and increment
	and		#0xFF, A	; mask
	stl		A, *AR4+	; save
	mar		*AR1+		; count bytes
	
	cmpr	LT, AR1				; If we're not done with a bridged data sequence, 
	nop
	nop
	xc		1, NTC
	rsbx	BRAF
	nop
	nop
	nop
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
	
	addm	#1, @minor_count
	nop
	nop
	stm		#(lsb_sel), AR0
	portw	AR0, wr_disc

; buffer is now loaded
	call	rsp_clear	; clear NCO RAM, do it here since we have some free time

; Strobe watchdog- once per minor frame cycle
	stm		#0, AR0        ; Data is not used- just the wr_dog strobe
	portw	AR0,wr_dog     ; Strobe the watchdog

; clear interrupt flags, then idle until an interrupt.
	.global pre_sleep
pre_sleep:
	
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
	
	mvmd	BSPCE0, @bspce_save ; store control extension register
	
; if this is a new major frame, we need to sync
; everyone up by waiting for all ABU haltx.

	bitf	BSPCE0, #bspce_haltx
	bc		abu_restart_skip, NTC

abu_haltx_wait:
	.global	abu_haltx_wait

	; ABU has halted.  Reset ABU, and synchronize
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx ABU, disable haltx

	call	sync_units
	
	; Start BSP transmits
	stm		#(bspc_Free + bspc_fsm + bspc_nXrst), BSPC0	; have to hold fsm bit
	nop
	nop
	
	rpt		#16383
	nop
	
; unset acq_seq, keep lsb_sel
	stm		#lsb_sel, AR0
	portw	AR0, wr_disc

abu_restart_skip:
	.global	abu_restart_skip
	
	mvdm	@bridge_size, AR0	; need to copy these 
	mvdm	@bridge_count, AR1	; to use CMPR
	nop
	nop
	cmpr	LT, AR1				; If we're not done with a bridged data sequence, 
	bc		bridge_data, TC	; jump to bridge_data to continue transfers, otherwise...

	dld		@major_count, A	; increment major frame counter
	add		#1, A
	dst		A, @major_count
	
	; The final half is transmitting, we want to halt when it finishes.
	stm		#(acq_test4+lsb_sel), AR0
	portw	AR0, wr_disc
	orm		#bspce_haltx, BSPCE0
	nop
	nop
;	stm		#(lsb_sel), AR0
;	portw	AR0, wr_disc

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
	stm		#npmst, PMST	; Reset PMST to be sure IPTR -> 0x80
	
; Alternative: IPTR=0x1FF, OVLY=1, all else =0
; This should set things up to completely reload the program from the EPROM on reset
;	stm		#0xFFA0, PMST

	reset	; I don't have to take this.  ...I'm going home.
	
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

****
* cfreq_walk
*
* walks through the table of center frequencies at label #cfreq_table
*
* stores table position @cfreq_tp and current NCO value as a 32-bit number @nco_freq
*
****

cfreq_walk:

	portr	rd_disc, AR0
	nop
	nop
	bitf	AR0, #trm_28
	bc		walk_skip, NTC	; if trm_28 is low (NTC, jumper on), skip the walk

	addm	#2, @cfreq_tp
	nop
	nop
	cmpm	@cfreq_tp, #cfreq_table_sz
	nop
	nop
	xc		2, TC
	st		#0, @cfreq_tp
	
	nop
	nop
	
	ld		#(cfreq_table), A
	add		@cfreq_tp, A
	stlm	A, AR0
	nop
	nop
	ld		*AR0+, B
	stl		B, @nco_freq
	sftl	B, #8
	sftl	B, #8
	ld		*AR0, A
	stl		A, @(nco_freq+1)
	or		B, A

	b		cfreq_commit

walk_skip:
	; load a single frequency instead
	; in two parts because there's no 32-bit immediate load op
	
	ld		#cfreq_test1, #16, A
	or		#cfreq_test2, A
	
cfreq_commit:
	
	nop
	nop		

	call	rsp_freq
		
	retd
	nop
	nop


****
* sync_units
*
* synchronizes master/slave units by toggling and waiting for latched lines
*
****

sync_units:
	
	; Raise test2 line.  On the Master this should do nothing (NC),
	; on the Slaves it signals the Master they are ready.

	stm		#(acq_seq_rdy+lsb_sel), AR0
	portw	AR0, wr_disc
	nop
	nop
	
	; Check status of TSP, wait for IN1 & IN2 high
ready_loop:

	nop
	
	bitf	TSPC, #tspc_in0
	bc		ready_loop, NTC
	
	bitf	TSPC, #tspc_in1
	bc		ready_loop, NTC
	
	; Raise acq_seq_out--on the Master this signals the Slaves to start, 
	; on the Slaves it does nothing (NC).
	
	stm		#(acq_seq_out+acq_seq_rdy+lsb_sel), AR0 ; send acq_seq_out
	portw	AR0, wr_disc

	retd
	nop
	nop
	
	
****
* hwrite
*
* Writes a 32-bit header:
*
* <0xFE6B2840><RxDSP><Unit #><Ver #><NCOF><MFCB><00000000>
*
****

	.mmregs

hwrite:
	.global	hwrite

	pshm	AR3

; 4-byte sync
	stm		#static_header, AR3	; Point to static header words
	rpt		#static_header_len		; <SYNC><RxDSP>
	mvdd	*AR3+, *AR4+
	
	ld		*(unit_designation), A
	add		#0x30, A	; we want the header unit number to be in ASCII
	stl		A, *AR4+
	
	stm		#station_code, AR3
	rpt		#1
	mvdd	*AR3+, *AR4+
	
	stm		#code_version, AR3
	rpt		#3
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
	
	rpt		#3
	st		#0, *AR4+
	
	popm	AR3
	
	retd
	nop
	nop

static_header:
		.word	0xFE, 0x6B, 0x28, 0x40
		.string	"RxDSP"
static_header_end:
	
static_header_len	.set	static_header_end-static_header-1

;	.include "ad6620.asm"
;	.include "cbrev.asm"

	.end