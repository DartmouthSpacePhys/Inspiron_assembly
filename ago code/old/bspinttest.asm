	.mmregs
	.global ZERO, BMAR, PREG, DBMR, INDX, ARCR, TREG1
	.global TREG2, CBSR1, CBER1, CBSR2, CBER2
	.text
	
;
; System-specific constants
;
npmst	.set	0000000010100000b
				; Processor mode and status
				; IPTR to page 1 (9 MSBs)
				; MP/MC = 0, microcontroller
				; OVLY = 1
				; AVIS = 0
				; DROM = 0
				; CLKOFF = 0 (CLKOUT is active)
				; SMUL = 0
				; SST = 0
prom	.set	8000h		; EEPROM base address
scratch	.set	0060h		; Scratchpad RAM 0060h - 007Fh
stack	.set	27F0h		; Stack pointer to high RAM
;
; System I/O
;
; Output Strobes
;
wr_rs_rx .set	0000h		; Write to reset AD6620
wr_out0	.set	2000h		; Write to spare LVDS OUT0
wr_out1	.set	4000h		; Write to spare LVDS OUT1
wr_rx		.set	4000h		; Updated RSP write address to avoid boot conflict
wr_rd_fifo	.set	6000h		; Write strobe to force TLM FIFO read
wr_disc	.set	8000h		; Write to discrete output latch
wr_dog	.set	0A000h	; Strobe watchdog timer chip
wr_out	.set	0C000h	; Output write; can be jumpered to FIFO
wr_rsv	.set	0E000h	; Write reserved/spare
;
; Input Strobes
;
rd_rx_out	.set	0000h		; Read Rx FIFO word (output enable)
clk_rx_out	.set	2000h		; Read strobe to clock next word from FIFO
rd_rx		.set	4000h		; Read AD6620 RSP registers
rd_out2	.set	6000h		; Strobe differential driver 30
rd_disc	.set	8000h		; Read discrete inputs
rs_rx_fifo	.set	0A000h	; Rx FIFO reset strobe
rs_fifo	.set	0C000h	; TLM FIFO reset strobe
rd_rsv	.set	0E000h	; Read address reserved for boot operation 
;
; Software Wait State Register (SWWSR) bit shifts
;
; Number of bits to shift to get to the base of a 3-bit wait 
; state definition.  These set the number of extra cycles to add 
; to a Program Space (PS), Data Space (DS), or I/O Space (IS) 
; access.  PS and DS are split.
;
swwsr_ps0	.set	0	; 0000-7FFFh Program
swwsr_ps1	.set	3	; 8000-FFFFh Program
swwsr_ds0	.set	6	; 0000-7FFFh Data
swwsr_ds1	.set	9	; 8000-FFFFh Data
swwsr_is	.set	12	; 0000-FFFFh I/O

; Example to set wait states
;	ldm		SWWSR, A
;	xor		#7, #swwsr_is, A ; (A xor 0b111<<Nset) to zero bits of set Nset
;	or		#0, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
;	stlm	A, SWWSR
;
; Internal timer bit and timing definitions
;
ntss	.set	16		; TSS (timer stop) bit in TCR
ntddr	.set	0		; Timer prescaler load value ("divide by 1")
						; See timer value calculations below
nload	.set	32		; TRB (timer reload bit) in TCR
nprd	.set	2399	; Minor frame test (60 us / 25 ns)/(ntddr+1)-1
nwait	.set	1599	; (40 us / 25 ns)/(ntddr+1)-1

;
; Interrupt flag bit masks: TMS320C542 nomenclature
;
int_0	.set	0001h		; Interrupt 0 (major)
int_1	.set	0002h		; Interrupt 1 (minor)
int_2	.set	0004h		; Interrupt 2 (word- not used- boot-up issues)
int_t	.set	0008h		; Timer (for test purposes)
int_br	.set	0010h		; BSP receive int
int_bx	.set	0020h		; BSP transmit int
int_tr	.set	0040h		; TSP receive int
int_tx	.set	0080h		; TSP transmit int
int_3	.set	0100h		; Interrupt 3 (Aux)

;
; AD6620 RSP register offsets
; Add to rd_rx/wr_rx to build final AD6620 External Interface Register Address
;
dr0	.set	0			; Data register 0, D[7:0]
dr1	.set	1			; Data register 1, D[15:8]
dr2	.set	2			; Data register 2, D[23:16]
dr3	.set	3			; Data register 3, D[31:24]
dr4	.set	4			; Data register 4, D[35:32]
rsv	.set	5			; Reserved
lar	.set	6			; Low address register A[7:0]
amr	.set	7			; Address mode register
					; 7: Write increment
					; 6: Read increment
					; 5-2: Reserved
					; 1-0: A[9:8]

;
; Discrete input bits at 8000h
;
trm_28	.set	0001h		; Terminal input (hardware EEPROM WR enable)
test_28	.set	0002h		; Test input
;
; Character constants
;
CR      .set    0Dh 
LF      .set    0Ah 
CRLF    .set    0D0Ah		; CR, LF as 1 word 
ESC     .set    1Bh 
;
;	Interrupt Vectors, RAM Page 1
;
START:
	b	mon		; Reset/SINTR 0
	nop
	nop
;
	b	mon		; NMI/SINT16 1
	nop
	nop
;
	b	mon		; SINT17 2
	nop
	nop
;
	b	mon		; SINT18 3
	nop
	nop
;
	b	mon		; SINT19 4
	nop
	nop
;
	b	mon		; SINT20 5
	nop
	nop
;
	b	mon		; SINT21 6
	nop
	nop
;
	b	mon		; SINT22 7
	nop
	nop
;
	b	mon		; SINT23 8
	nop
	nop
;
	b	mon		; SINT24 9
	nop
	nop
;
	b	mon		; SINT25 10
	nop
	nop
;
	b	mon		; SINT26 11
	nop
	nop
;
	b	mon		; SINT27 12
	nop
	nop
;
	b	mon		; SINT28 13
	nop
	nop
;
	b	mon		; SINT29 14
	nop
	nop
;
	b	mon		; SINT30 15
	nop
	nop
;
	b	mon		; INT0/SINT0 16
	nop
	nop
;
	b	mon		; INT1/SINT1 17
	nop
	nop
;
	b	mon		; INT2/SINT2 18
	nop
	nop
;
	b	mon	; TINT/SINT3 19 (just returns)
;	b	minor_int	; Test code with timer
	nop
	nop
;
	b	mon		; BRINT0/SINT4 20
	nop
	nop
;
	b	mon		; BXINT0/SINT5 21
	nop
	nop
;
	b	mon		; TRINT0/SINT6 22
	nop
	nop
;
	b	mon		; TXINT0/SINT7 23
	nop
	nop
;
	b	mon		; INT3/SINT8 24
	nop
	nop
;
	b	mon		; HPINT/SINT9 25
	nop
	nop
;		
	b	mon		; Reserved vector 26
	nop
	nop
;		
	b	mon		; Reserved vector 27
	nop
	nop
;		
	b	mon		; Reserved vector 28
	nop
	nop
;		
	b	mon		; Reserved vector 29
	nop
	nop
;		
	b	mon		; Reserved vector 30
	nop
	nop
;		
	b	mon		; Reserved vector 31
	nop
	nop
;
; Start of Monitor Code - RAM page 1
;
mon:
	ssbx    INTM	; Disable interrupts 
	stm		#0, IMR	; mask all interrupts
	stm	#stack,SP	; Stack pointer to high RAM
	stm	#npmst,PMST	; Set processor mode/status
	rsbx	SXM		; Suppress sign extension 
	nop			; Space for branch to app
	nop
 
;
; Constants
;
iq_len		.set	63		; N+1 words before I/Q off, LSB on
acq_seq_len .set 	32767   ; N+1 words to hold acq_seq high
seq_len		.set	65535	; Total N+1 words per trigger

;
; Discrete Outputs (at wr_disc)
;
par_tm_en	.set	1	; Parallel telemetry enable (active low)
lsb_sel		.set	2	; LSB/I_Q select, low for I_Q
acq_seq_out	.set	128	; ACQ_SEQ output bit 
;
; Discrete Inputs (at rd_disc)
;
disc_0		.set	1	; Same as trm_28 at monitor level
acq_seq_in	.set	2	; Dartmouth slave ACQ_SEQ input
tlm_ffo		.set	4	; Telemetry FIFO full flag
tlm_efo		.set	8	; Telemetry FIFO empty flag
tlm_hfo		.set	16	; Telemetry FIFO half-full flag
rx_ffo		.set	32	; Rx FIFO full flag
rx_efo		.set	64	; Rx FIFO empty flag
rx_hfo		.set	128	; Rx FIFO half-full flag

; Buffered Serial Port Control Register bit definitions

bspc_dlb	.set	2		; digital loopback
bspc_fo		.set	4		; format
bspc_fsm	.set	8		; frame sync mode
bspc_mcm	.set	16		; clock mode
bspc_txm	.set	32		; transmit mode
bspc_nXrst	.set	64		; transmit reset
bspc_nRrst	.set	128		; receive reset
bspc_in0	.set	256		; binary state of receive clock line (r/o)
bspc_in1	.set	512		; binary state of transmit clock line (r/o)
bspc_Rrdy	.set	1024	; receive ready (r/o)
bspc_Xrdy	.set	2048	; transmit ready (r/o)
bspc_XSRfull .set	4096	; Transmit Shift Register full (r/o)
bspc_RSRfull .set	8192	; Receive Shift Register full (r/o)
bspc_Soft	.set	16384	; HLL debugging clock behavior bit
bspc_Free	.set	32768	; HLL debugging clock behavior bit

; Buffered Serial Port Control Extension Register bit definitions

; bits 0-4 are the clock division bits
bspce_fsp	.set	32		; frame sync polarity
bspce_clkp	.set	64		; clock polarity
bspce_fe	.set	128		; format extension
bspce_fig	.set	256		; continuous mode frame sync ignore
bspce_pcm	.set	512		; pulse code modulation mode
bspce_bxe	.set	1024	; autobuffer transmit enable
bspce_xh	.set	2048	; autobuffer transmit half completed (r/o)
bspce_haltx	.set	4096	; autobuffer transmit half halt
bspce_bre	.set	8192	; autobuffer receive enable
bspce_rh	.set	16384	; autobuffer receive half completed (r/o)
bspce_haltr	.set	32768	; autobuffer receive half halt


abu_buff_loc	.set	0800h	; serial buffer start location
abu_buff_sz		.set	512		; size of serial buffer (2x burst size)
abu_buff_hsz		.set	256		; half size of serial buffer (2x burst size)
data_addr	.set		0100h	
burst_size	.set	1 ; number of acquisitions per half-buffer interrupt

	ssbx	XF
	rsbx	XF
	rpt #31
	nop
	ssbx	XF
	rsbx	XF

	rpt	#100
	nop
;
; Initialization
;
appcode:
	nop
	nop
	ssbx	INTM
	rsbx	XF
;	stm	#0,state	; Clear interrupt routine state
	stm	#0,AR0		; Clear auxilliary register 0
	portw	AR0,wr_rs_rx	; Reset AD6620 RSP
	portw	AR0,wr_disc	; Enable parallel TLM drivers, I_Q out
	portw	AR0,wr_dog	; Strobe watchdog timer
	
	stm	#0,AR0	; Clear auxilliary registers
	stm	#0,AR1
	stm	#0,AR2
	stm	#0,AR3
	stm	#0,AR4
	stm	#0,AR5
	stm	#0,AR6
	stm	#0,AR7

	stm		#0FFh,IFR	; Clear any pending interrupts
	stm	#ntss,TCR	; Stop timer, if running
	
;
; Set up AD6620 from table
;

read_init:
	ld		#ad6620_soft_reset, A
	call	rsp_setup
	
	ld		#ad6620_filter,A ; Set up AD6620 filter
	call	rsp_setup

	stm		#0, AR0			; Reset discrete outputs (acq_seq & lsb_sel)
	portw	AR0, wr_disc
	

	stm		#(bspc_fsm), BSPC0 		; reset BSP
	stm		#(int_br+int_bx), IFR	; clear serial interrupts
	stm		#(int_bx), IMR			; unmask serial interrupts
	rsbx	INTM ; global interrupt enable
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx autobuffer
	stm		#(abu_buff_loc), AXR	
	stm		#(abu_buff_sz), BKX
	stm		#(bspc_fsm + bspc_nXrst), BSPC0		; bring transmits out of reset

	ssbx	XF
	rpt #19
	nop
	rsbx	XF
	
	ssbx	INTM
	
bspint_test:
	IDLE	3
	
	stm		#int_bx, IFR ; clear serial tx int
	
	stm		#acq_seq_out, AR0 ; send acq_seq to slave
	portw	AR0,wr_disc
	nop
	nop

	ssbx	XF
	rpt		#9
	nop
	rsbx	XF
	
	rpt		#100
	nop
	
	stm		#0, AR0
	portw	AR0, wr_disc
		
	rpt		#100
	nop
	
	b		bspint_test


timer_int:
	reted
	portw	0, wr_dog     ; Strobe the watchdog
; timer_int done

;;
; Test of AD6620 set-up from look-up table
;;

table_test:
	ld      #000Dh,A	; Output CR 
;	call	asx
	ld      #000Ah,A	; LF 
;	call	asx

	ld	#ad6620_filter,A
	call	rsp_setup
	b	bspint_test

;
; Load RSP (AD6620) Registers from Table
;
; 23 Dec 2009 took out most writes to terminal (msgout, dis4hex, asx)
;
; This code was taken directly from the "rspmod" routine used in the
; Dartmouth Monitor. Instead of having the user enter the data words
; or receiving them from a "script" file, this routine looks at a
; table of words in memory, reads them, and transfers them to the
; AD6620. Used to load control bytes and filter coefficients.
;
; Table entry format:
;
; rsp_table:
;	.word	AmLah, r4r3h, r2r1h, r0xxh;
;	.word	(more 4-word entries)
;	.word	0FFFFh	; End of table
;
; 4 words:
; AAaah = AD6620 internal address, 0000h to 030Dh, or FFFFh to terminate.
;         AMR = Ma Address mode register
;         LAR = La Lower address register
; r4r3h, r2r1h, r0xxh = data bytes, packed into words, MS, to LS. Bottom byte
;         of 3rd word not used (xx). Data is treated a 40 bits for all
;         AD6620 registers. Not the most compact arrangement for storage,
;         but readable- and it can be edited directly from monitor scripts.
;
;         DR4 = r4
;         DR3 = r3
;         DR2 = r2
;         DR1 = r1
;         DR0 = r0 
;
; Uses:
; A:   Holds table pointer upon entry 
; B:   Working register
; AR0: I/O address
; AR2: Table index
; AR3: Holds data to send to or read from I/O port
;
table_end .set 0FFFFh		; End-of-table definition

rsp_setup:			; Enter with table starting address in A
	stlm    A,AR2		; Save to AR2 for later use
	nop 			; Necessary for loop to execute properly (?!&)
	nop 			; Necessary for loop to execute properly (?!&)
;	ld	#ad6620_msg1,A	; Tell operator what is happening
;	call	msgout	

rsp_loop:
;	ldm	AR2,A		; Retrieve table index
;	call	dis4hex		; Display index of table line
;	ld      #0020h,A	; Space over on screen 
;	call	asx

	cmpm	*AR2,#table_end	; Is this the end of the table?
	bc	rspx,TC		; Return if at end		

	ld	*AR2+,A		; Get first table word: AD6620 address
	ld	A,B		; Save a copy

;	call	dis4hex		; Display
;
; Transfer RSP register address bytes to AD6620 high and low address registers
;
	sftl	A,-8,A		; Shift high byte to low byte
	and	#0003h,A,A	; Mask high byte to 2 LSBs (avoid reserved bits
				; and do not auto-increment for now)
	stlm	A,AR3		; Move to AR3 for portw
	portw AR3,wr_rx+amr	; Write to high address register
	ld	B,A		; Get RSP register address
	and	#00FFh,A,A	; Mask to low byte only (actually hardware
				; only uses bits 7:0 of data bus, should not
				; need to mask)
	stlm	A,AR3
	portw AR3,wr_rx+lar	; Write to low address register

;	ld	#0020h,A	; Space over
;	call	asx

	ld	*AR2+,A		; Get next table word (dr4 and dr3 bytes)
	ld	A,B		; Save a copy

;	call	dis4hex		; Display

	sftl	A,-8,A		; Shift high byte to low byte
	stlm	A,AR3		; AR3 holds output data
	portw	AR3,wr_rx+dr4	; Store to AD6620 MS data byte register

	ld	B,A		; Get copy
	and	#00FFh,A,A	; Mask to low byte only
	stlm	A,AR3
	portw	AR3,wr_rx+dr3

;	ld	#0020h,A	; Space over
;	call	asx

	ld	*AR2+,A		; Get next table word (dr2 and dr1 bytes)
	ld	A,B		; Save a copy

;	call	dis4hex		; Display

	sftl	A,-8,A		; Shift high byte to low byte
	stlm	A,AR3
	portw	AR3,wr_rx+dr2

	ld	B,A		; Get copy
	and	#00FFh,A,A	; Mask to low byte only
	stlm	A,AR3
	portw	AR3,wr_rx+dr1

;	ld	#0020h,A	; Space over
;	call	asx

	ld	*AR2+,A		; Get next table word (dr0 in upper byte)

;	call	dis4hex		; Display

	sftl	A,-8,A		; Shift high byte to low byte
	stlm	A, AR3		; Save for subsequent output port write
	portw	AR3,wr_rx+dr0	; Address for RSP LS data byte

;	ld	#0020h,A	; Space over
;	call	asx
;	ld      #000Dh,A	; Output CR 
;	call	asx
;	ld      #000Ah,A	; LF 
;	call	asx

	b	rsp_loop	; Go back for next table entry
rspx:
;	ld	#ad6620_msg2,A
;	call	msgout
	ret

;
; Receiver telemetry static header
;
; Comment/uncomment as needed for master/slave

static_header:
	.pstring	"Dartmouth College Rx-DSP, AGO Unit T, test v3"
	.word	0000h	; Null terminator
	
;
; Receiver telemetry static header
;
; Comment/uncomment as needed for master/slave

master_header:
	.pstring	"Dartmouth College Master RxDSP  "
	.word	0000h	; Null terminator
	
slave_header:
	.pstring	"Dartmouth College Slave  RxDSP  "
	.word	0000h	; Null terminator
;
; AD6620 set-up messages
;
static_minor_footer:
	.word	0DA27h ; 1101101000100111
	.word	0FFFFh ; 1111111111111111
	.word	0AAAAh ; 1010101010101010
	.word	01B33h ; 1100110011001100
	.word	0000h ; Null Terminator

ad6620_msg1:
	.word	0D0Ah
	.pstring "AD6620 set-up: MASTER "
;S    .pstring "AD6620 set-up: SLAVE  "
	.word	0D0Ah,0000h
ad6620_msg2:
	.word	0D0Ah
	.pstring "AD6620 set-up complete"
	.word	0D0Ah,0000h

;
; AD6620 Set-Up Tables:
; See subroutine rsp_setup for format details.
; Briefly, AD6620 internal address word is
; followed by 3 words containing up to 40
; bits of set-up data. The last byte is not used.
; Table end is denoted by 0FFFFh in the address
; field.
;
; *** Note *** be sure to comment/uncomment Master/Slave table entries
; as needed at beginning and end of table
;
;
; AD6620 set-up captured from AD6620.exe "dialog"
; Filter source file: ad_4_5_10.f20
; View frequency response using Analog Devices FilterDesign.exe
;
; Design specs
; Frequency out from NCO center)   Attenuation
; 0 kHz (implied)                      0 dB
; 150 kHz                              0 dB
; 166.67 kHz                         -60 dB
; 1 dB of passband ripple
; Input sampling rate            66.6666 MHz
; Output rate                    333.333 kHz
; Decimation factor                  200
;
; Response from plot
; -3dB at 154 kHz
; -6dB at 156 kHz
; -66 dB in the stopband (166.67 kHz and greater).
; Passband looks very flat out to 150 kHz, but if you zoom in on the
; plot, you can see less than 0.5 dB of ripple, about 0.42 dB or so.
;
;
; Converted to assembly ".word" directives in Excel spreadsheet m4510.xls
 
ad6620_filter:
        .word    0301h, 00000h, 00000h, 00000h	; NCO Control
        .word    0302h, 000FFh, 0FFFFh, 0FF00h	; NCO Sync Mask
;        .word    0303h, 0000Ah, 08F5Ch, 0DA00h	; NCO Frequency = 2.75 MHz
; 23 Dec 2009
;        .word    0303h, 0000Ah, 040B8h, 02C00h  ; NCO Frequency = 2.67 MHz
;        .word    0303h, 00005h, 09168h, 0D000h  ; NCO Frequency = 1.45 MHz
        .word    0303h, 00001h, 0FA44h, 02000h  ; NCO Frequency = 515 MHz
        .word    0304h, 00000h, 00000h, 00000h	; NCO Phase Offset
        .word    0305h, 00000h, 00000h, 00500h	; Input/CIC2 Scale
        .word    0306h, 00000h, 00000h, 00900h	; MCIC2-1
        .word    0307h, 00000h, 00000h, 00700h	; CIC5 Scale
        .word    0308h, 00000h, 00000h, 00400h	; MCIC5-1
        .word    0309h, 00000h, 00000h, 00400h	; Output/RCF Control
        .word    030Ah, 00000h, 00000h, 00300h	; MRCF-1
        .word    030Bh, 00000h, 00000h, 00000h	; RFC Address Offset
        .word    030Ch, 00000h, 00000h, 0C700h	; Ntaps-1
        .word    030Dh, 00000h, 00000h, 00000h	; Reserved (zero)
        .word    0000h, 00000h, 00005h, 0D300h	; RCF Filter Coefficients
        .word    0001h, 0FFFFh, 0FFFEh, 03C00h	
        .word    0002H, 0FFFFH, 0FFFFH, 09900H	
        .word    0003H, 0FFFFH, 0FFF5H, 08F00H	
        .word    0004H, 0FFFFH, 0FFEFH, 0D500H	
        .word    0005H, 0FFFFH, 0FFE6H, 09B00H	
        .word    0006H, 0FFFFH, 0FFE3H, 0FA00H	
        .word    0007H, 0FFFFH, 0FFE4H, 0C300H	
        .word    0008H, 0FFFFH, 0FFEDH, 04C00H	
        .word    0009H, 0FFFFH, 0FFF8H, 08600H	
        .word    000AH, 00000H, 00005H, 00900H	
        .word    000BH, 00000H, 0000CH, 0B000H	
        .word    000CH, 00000H, 0000EH, 03B00H	
        .word    000DH, 00000H, 00008H, 03B00H	
        .word    000EH, 0FFFFH, 0FFFEH, 0C000H	
        .word    000FH, 0FFFFH, 0FFF5H, 08A00H
        .word    0010H, 0FFFFH, 0FFF1H, 0E200H
        .word    0011H, 0FFFFH, 0FFF5H, 01800H
        .word    0012H, 0FFFFH, 0FFFEH, 04900H
        .word    0013H, 00000H, 00008H, 08100H
        .word    0014H, 00000H, 0000EH, 0F700H
        .word    0015H, 00000H, 0000DH, 0B300H
        .word    0016H, 00000H, 00005H, 05300H
        .word    0017H, 0FFFFH, 0FFF9H, 07900H
        .word    0018H, 0FFFFH, 0FFF0H, 07500H
        .word    0019H, 0FFFFH, 0FFEEH, 0F300H
        .word    001AH, 0FFFFH, 0FFF6H, 07D00H
        .word    001BH, 00000H, 00003H, 07F00H
        .word    001CH, 00000H, 0000FH, 0A800H
        .word    001DH, 00000H, 00014H, 04F00H
        .word    001EH, 00000H, 0000EH, 09500H
        .word    001FH, 00000H, 00000H, 09C00H
        .word    0020H, 0FFFFH, 0FFF1H, 06300H
        .word    0021H, 0FFFFH, 0FFE8H, 0BD00H
        .word    0022H, 0FFFFH, 0FFEBH, 0E200H
        .word    0023H, 0FFFFH, 0FFF9H, 0E700H
        .word    0024H, 00000H, 0000CH, 04100H
        .word    0025H, 00000H, 00019H, 06500H
        .word    0026H, 00000H, 0001AH, 00500H
        .word    0027H, 00000H, 0000CH, 0D100H
        .word    0028H, 0FFFFH, 0FFF7H, 0DA00H
        .word    0029H, 0FFFFH, 0FFE5H, 0A500H
        .word    002AH, 0FFFFH, 0FFE0H, 03100H
        .word    002BH, 0FFFFH, 0FFEBH, 03A00H
        .word    002CH, 00000H, 00002H, 02E00H
        .word    002DH, 00000H, 00019H, 0A200H
        .word    002EH, 00000H, 00025H, 02700H
        .word    002FH, 00000H, 0001DH, 0B100H
        .word    0030H, 00000H, 00005H, 0DF00H
        .word    0031H, 0FFFFH, 0FFE9H, 02400H
        .word    0032H, 0FFFFH, 0FFD6H, 08400H
        .word    0033H, 0FFFFH, 0FFD8H, 0A600H
        .word    0034H, 0FFFFH, 0FFEFH, 0F900H
        .word    0035H, 00000H, 00011H, 09100H
        .word    0036H, 00000H, 0002CH, 04A00H
        .word    0037H, 00000H, 00031H, 05000H
        .word    0038H, 00000H, 0001CH, 06100H
        .word    0039H, 0FFFFH, 0FFF6H, 0AA00H
        .word    003AH, 0FFFFH, 0FFD3H, 01A00H
        .word    003BH, 0FFFFH, 0FFC4H, 0DB00H
        .word    003CH, 0FFFFH, 0FFD5H, 02F00H
        .word    003DH, 0FFFFH, 0FFFDH, 0B900H
        .word    003EH, 00000H, 0002AH, 0A700H
        .word    003FH, 00000H, 00044H, 04200H
        .word    0040H, 00000H, 0003BH, 04A00H
        .word    0041H, 00000H, 00011H, 0BE00H
        .word    0042H, 0FFFFH, 0FFDBH, 04800H
        .word    0043H, 0FFFFH, 0FFB4H, 00300H
        .word    0044H, 0FFFFH, 0FFB2H, 05800H
        .word    0045H, 0FFFFH, 0FFDAH, 05200H
        .word    0046H, 00000H, 0001AH, 01E00H
        .word    0047H, 00000H, 00051H, 08200H
        .word    0048H, 00000H, 00061H, 0F300H
        .word    0049H, 00000H, 0003EH, 0FB00H
        .word    004AH, 0FFFFH, 0FFF6H, 09A00H
        .word    004BH, 0FFFFH, 0FFACH, 03B00H
        .word    004CH, 0FFFFH, 0FF87H, 0CD00H
        .word    004DH, 0FFFFH, 0FFA0H, 0E000H
        .word    004EH, 0FFFFH, 0FFF0H, 06C00H
        .word    004FH, 00000H, 00051H, 05000H
        .word    0050H, 00000H, 00091H, 00000H
        .word    0051H, 00000H, 00089H, 00300H
        .word    0052H, 00000H, 00034H, 0D300H
        .word    0053H, 0FFFFH, 0FFB8H, 07000H
        .word    0054H, 0FFFFH, 0FF52H, 03500H
        .word    0055H, 0FFFFH, 0FF3DH, 02500H
        .word    0056H, 0FFFFH, 0FF91H, 02300H
        .word    0057H, 00000H, 00031H, 02B00H
        .word    0058H, 00000H, 000D2H, 08F00H
        .word    0059H, 00000H, 0011CH, 0AC00H
        .word    005AH, 00000H, 000D4H, 0AD00H
        .word    005BH, 00000H, 00001H, 05100H
        .word    005CH, 0FFFFH, 0FEF4H, 09300H
        .word    005DH, 0FFFFH, 0FE33H, 01500H
        .word    005EH, 0FFFFH, 0FE40H, 0D400H
        .word    005FH, 0FFFFH, 0FF66H, 0CA00H
        .word    0060H, 00000H, 0018BH, 03F00H
        .word    0061H, 00000H, 0042FH, 00200H
        .word    0062H, 00000H, 00694H, 01D00H
        .word    0063H, 00000H, 007FFH, 0FF00H
        .word    0064H, 00000H, 007FFH, 0FF00H
        .word    0065H, 00000H, 00694H, 01D00H
        .word    0066H, 00000H, 0042FH, 00200H
        .word    0067H, 00000H, 0018BH, 03F00H
        .word    0068H, 0FFFFH, 0FF66H, 0CA00H
        .word    0069H, 0FFFFH, 0FE40H, 0D400H
        .word    006AH, 0FFFFH, 0FE33H, 01500H
        .word    006BH, 0FFFFH, 0FEF4H, 09300H
        .word    006CH, 00000H, 00001H, 05100H
        .word    006DH, 00000H, 000D4H, 0AD00H
        .word    006EH, 00000H, 0011CH, 0AC00H
        .word    006FH, 00000H, 000D2H, 08F00H
        .word    0070H, 00000H, 00031H, 02B00H
        .word    0071H, 0FFFFH, 0FF91H, 02300H
        .word    0072H, 0FFFFH, 0FF3DH, 02500H
        .word    0073H, 0FFFFH, 0FF52H, 03500H
        .word    0074H, 0FFFFH, 0FFB8H, 07000H
        .word    0075H, 00000H, 00034H, 0D300H
        .word    0076H, 00000H, 00089H, 00300H
        .word    0077H, 00000H, 00091H, 00000H
        .word    0078H, 00000H, 00051H, 05000H
        .word    0079H, 0FFFFH, 0FFF0H, 06C00H
        .word    007AH, 0FFFFH, 0FFA0H, 0E000H
        .word    007BH, 0FFFFH, 0FF87H, 0CD00H
        .word    007CH, 0FFFFH, 0FFACH, 03B00H
        .word    007DH, 0FFFFH, 0FFF6H, 09A00H
        .word    007EH, 00000H, 0003EH, 0FB00H
        .word    007FH, 00000H, 00061H, 0F300H
        .word    0080H, 00000H, 00051H, 08200H
        .word    0081H, 00000H, 0001AH, 01E00H
        .word    0082H, 0FFFFH, 0FFDAH, 05200H
        .word    0083H, 0FFFFH, 0FFB2H, 05800H
        .word    0084H, 0FFFFH, 0FFB4H, 00300H
        .word    0085H, 0FFFFH, 0FFDBH, 04800H
        .word    0086H, 00000H, 00011H, 0BE00H
        .word    0087H, 00000H, 0003BH, 04A00H
        .word    0088H, 00000H, 00044H, 04200H
        .word    0089H, 00000H, 0002AH, 0A700H
        .word    008AH, 0FFFFH, 0FFFDH, 0B900H
        .word    008BH, 0FFFFH, 0FFD5H, 02F00H
        .word    008CH, 0FFFFH, 0FFC4H, 0DB00H
        .word    008DH, 0FFFFH, 0FFD3H, 01A00H
        .word    008EH, 0FFFFH, 0FFF6H, 0AA00H
        .word    008FH, 00000H, 0001CH, 06100H
        .word    0090H, 00000H, 00031H, 05000H
        .word    0091H, 00000H, 0002CH, 04A00H
        .word    0092H, 00000H, 00011H, 09100H
        .word    0093H, 0FFFFH, 0FFEFH, 0F900H
        .word    0094H, 0FFFFH, 0FFD8H, 0A600H
        .word    0095H, 0FFFFH, 0FFD6H, 08400H
        .word    0096H, 0FFFFH, 0FFE9H, 02400H
        .word    0097H, 00000H, 00005H, 0DF00H
        .word    0098H, 00000H, 0001DH, 0B100H
        .word    0099H, 00000H, 00025H, 02700H
        .word    009AH, 00000H, 00019H, 0A200H
        .word    009BH, 00000H, 00002H, 02E00H
        .word    009CH, 0FFFFH, 0FFEBH, 03A00H
        .word    009DH, 0FFFFH, 0FFE0H, 03100H
        .word    009EH, 0FFFFH, 0FFE5H, 0A500H
        .word    009FH, 0FFFFH, 0FFF7H, 0DA00H
        .word    00A0H, 00000H, 0000CH, 0D100H
        .word    00A1H, 00000H, 0001AH, 00500H
        .word    00A2H, 00000H, 00019H, 06500H
        .word    00A3H, 00000H, 0000CH, 04100H
        .word    00A4H, 0FFFFH, 0FFF9H, 0E700H
        .word    00A5H, 0FFFFH, 0FFEBH, 0E200H
        .word    00A6H, 0FFFFH, 0FFE8H, 0BD00H
        .word    00A7H, 0FFFFH, 0FFF1H, 06300H
        .word    00A8H, 00000H, 00000H, 09C00H
        .word    00A9H, 00000H, 0000EH, 09500H
        .word    00AAH, 00000H, 00014H, 04F00H
        .word    00ABH, 00000H, 0000FH, 0A800H
        .word    00ACH, 00000H, 00003H, 07F00H
        .word    00ADH, 0FFFFH, 0FFF6H, 07D00H
        .word    00AEH, 0FFFFH, 0FFEEH, 0F300H
        .word    00AFH, 0FFFFH, 0FFF0H, 07500H
        .word    00B0H, 0FFFFH, 0FFF9H, 07900H
        .word    00B1H, 00000H, 00005H, 05300H
        .word    00B2H, 00000H, 0000DH, 0B300H
        .word    00B3H, 00000H, 0000EH, 0F700H
        .word    00B4H, 00000H, 00008H, 08100H
        .word    00B5H, 0FFFFH, 0FFFEH, 04900H
        .word    00B6H, 0FFFFH, 0FFF5H, 01800H
        .word    00B7H, 0FFFFH, 0FFF1H, 0E200H
        .word    00B8H, 0FFFFH, 0FFF5H, 08A00H
        .word    00B9H, 0FFFFH, 0FFFEH, 0C000H
        .word    00BAH, 00000H, 00008H, 03B00H
        .word    00BBH, 00000H, 0000EH, 03B00H
        .word    00BCH, 00000H, 0000CH, 0B000H
        .word    00BDH, 00000H, 00005H, 00900H
        .word    00BEH, 0FFFFH, 0FFF8H, 08600H
        .word    00BFH, 0FFFFH, 0FFEDH, 04C00H	
        .word    00C0H, 0FFFFH, 0FFE4H, 0C300H	
        .word    00C1H, 0FFFFH, 0FFE3H, 0FA00H	
        .word    00C2H, 0FFFFH, 0FFE6H, 09B00H	
        .word    00C3H, 0FFFFH, 0FFEFH, 0D500H	
        .word    00C4H, 0FFFFH, 0FFF5H, 08F00H	
        .word    00C5H, 0FFFFH, 0FFFFH, 09900H	
        .word    00C6H, 0FFFFH, 0FFFEH, 03C00H	
        .word    00C7H, 00000H, 00005H, 0D300H	; End RCF Filter Coefficients
        .word    0FFFFH	; End of Table
ad6620_filter_end:

ad6620_soft_reset:
	.word    0300H, 00000H, 00000H, 00100H	; Soft Reset (same for M & S)
	.word    0FFFFH	; End of Table
ad6620_soft_reset_end:

ad6620_master_run:
	.word    0300H, 00000H, 00000H, 00800H	; Run: end of soft reset, Master
	.word    0FFFFH	; End of Table
ad6620_master_run_end:

ad6620_slave_run:
	.word    0300h, 00000h, 00000h, 00000h  ; Run: end of soft reset, Slave
	.word    0FFFFH	; End of Table
ad6620_slave_run_end:

;
; NCO control "short tables"- use with ad6620_setup
;
NCO_1000_kHz:
        .word    0303h, 0003h, 0D70Ah, 7E00h; NCO Frequency = 1 MHz
        .word    0FFFFh
NCO_2750_kHz:
        .word    0303h, 0000Ah, 08F5Ch, 0DA00h	; NCO Frequency = 2.75 MHz
        .word    0FFFFh
NCO_250_kHz:
        .word    0303h, 00000h, 0F5C2h, 09F00h	; NCO Frequency = 250 kHz
        .word    0FFFFh
NCO_2670_kHz:
        .word    0303h, 0000Ah, 040B8h, 02C00h  ; NCO Frequency = 2.67 MHz
        .word    0FFFFh       
NCO_1450_kHz:
        .word    0303h, 00005h, 09168h, 0D000h  ; NCO Frequency = 1.45 MHz
        .word    0FFFFh       
NCO_515_kHz:
        .word    0303h, 00001h, 0FA44h, 02000h  ; NCO Frequency = 515 kHz
        .word    0FFFFh       

        .end
