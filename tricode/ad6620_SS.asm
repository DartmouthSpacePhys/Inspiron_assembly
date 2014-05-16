****
* AD6620 setup functions and tables
***

* History
* 
* v1.0 	3 June 2012	Converted from an .include file to a compilable, sectioned file.
*

	.mmregs
	.def	rsp_clear, rsp_reset, rsp_init, rsp_mstart, rsp_sstart, rsp_freq
;	.def	ad6620_soft_reset, ad6620_filter, ad6620_master_run, rsp_setup
	.include "rx-dsp.h"
	
ad6620_addr_MCR		.set		0x0300
ad6620_addr_freq	.set		0x0303
	
ad6620_soft_reset	.long	0x00000001	; Soft Reset (same for M & S)
ad6620_master_run	.long	0x00000008	; Run: end of soft reset, Master
ad6620_slave_run	.long	0x00000000	; Run: end of soft reset, Slave

	.sect	".ad6620"

*
* rsp_reset, rsp_init, rsp_mstart, rsp_sstart
* 	shell functions over rsp_setup
*	

rsp_reset:
	dld		*(ad6620_soft_reset), A 	; Put AD6620 into reset
	ld		#ad6620_addr_MCR, B		; Mode Control Register
	call	rsp_os
	
	ret
	
rsp_mstart:
	dld		*(ad6620_master_run), A	; Start digitizing as master
	ld		#ad6620_addr_MCR, B
	call	rsp_os
	
	ret
	
rsp_sstart:
	dld		*(ad6620_slave_run), A	; Start digitizing as slave
	ld		#ad6620_addr_MCR, B
	call	rsp_os
	
	ret
	
rsp_freq:
	; frequency already in A
	ld		#ad6620_addr_freq, B
	call	rsp_os
	
	ret
	
rsp_init:
	ld		#ad6620_filter, A 	; Set up AD6620 filter
	call	rsp_setup
	
	retd
	nop
	nop



*
* rsp_os	Receive Processor One-Shot
*			Quickly loads one 36-bit value to an address on the AD6620
*
rsp_os:
	; 36-bit value in A
	; 10-bit address in B
	
	; write address 0x0303 to address registers
	stl		B, #-8, AR4
	andm	#0x03, AR4	; mask to lower two bytes
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+amr
	
	stl		B, AR4
	andm	#0xFF, AR4
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+lar
	
	; write 36-bit value into five 8-bit data registers
	mvdm	@AG, AR4
	andm	#0x0F, AR4 		; 0x0F 0000 0000
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+dr4
	
	sth		A, #-8, AR4		; 0x00 FF00 0000
	andm	#0xFF, AR4
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+dr3
	
	sth		A, AR4			; 0x00 00FF 0000
	andm	#0xFF, AR4
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+dr2
	
	stl		A, #-8, AR4		; 0x00 0000 FF00
	andm	#0xFF, AR4
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+dr1
	
	stl		A, AR4			; 0x00 0000 00FF
	andm	#0xFF, AR4
	nop
	nop
	nop
	nop
	portw	AR4, wr_rx+dr0	; writing to dr0 commits
	
	retd
	nop
	nop	

	
*
* rsp_clear	Function to clear RCF Data RAM between frames
*

rsp_clear:
	stm		#100000001b, AR3	; address auto-increment mode + high bit of 0x100
	portw	AR3, (wr_rx+amr)
	stm		#0, AR3				; low byte of 0x100	
	portw	AR3, (wr_rx+lar)

	stm		#0xFF-1, BRC
	
	portw	AR3, (wr_rx+dr4)	; don't think
	portw	AR3, (wr_rx+dr3)	; we need
	portw	AR3, (wr_rx+dr2)	; to write
	portw	AR3, (wr_rx+dr1)	; these again

	rpt		#0xFF-1	
	portw	AR3, (wr_rx+dr0)

	retd
	nop
	nop
	
	
;;
; Test of AD6620 set-up from look-up table
;;

;table_test:
;	ld      #000Dh,A	; Output CR 
;	call	asx
;	ld      #000Ah,A	; LF 
;	call	asx
;
;	ld	#ad6620_filter,A
;	call	rsp_setup
;	b	monitor_entry

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
; 375 kHz                              0 dB
; 462.963 kHz                         -50 dB
; 1 dB of passband ripple
; Input sampling rate            66.6666 MHz
; Output rate                    833.3325 kHz
; Decimation factor                  80
;
;
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
        .word    0303h, 0000Eh, 06667h, 05800h	; NCO Frequency = 2.75 MHz
        .word    0304h, 00000h, 00000h, 00000h	; NCO Phase Offset
        .word    0305h, 00000h, 00000h, 00400h	; Input/CIC2 Scale
        .word    0306h, 00000h, 00000h, 00700h	; MCIC2-1	MCIC2 = 8
        .word    0307h, 00000h, 00000h, 00700h	; CIC5 Scale
        .word    0308h, 00000h, 00000h, 00400h	; MCIC5-1	MCIC5 = 5
        .word    0309h, 00000h, 00000h, 00400h	; Output/RCF Control
        .word    030Ah, 00000h, 00000h, 00100h	; MRCF-1	MRCF = 2
        .word    030Bh, 00000h, 00000h, 00000h	; RFC Address Offset
        .word    030Ch, 00000h, 00000h, 04700h	; Ntaps-1	Ntaps = 80
        .word    030Dh, 00000h, 00000h, 00000h	; Reserved (zero)
 		.word	0x0000, 0x0000, 0x0000, 0xE400	; RCF Filter Coefficients
		.word	0x0001, 0x0000, 0x0FFE, 0x3800
		.word	0x0002, 0x0000, 0x0000, 0x4500
		.word	0x0003, 0x0000, 0x0001, 0x8300
		.word	0x0004, 0x0000, 0x0000, 0x5500
		.word	0x0005, 0x0000, 0x0FFC, 0xBD00
		.word	0x0006, 0x0000, 0x0000, 0x3E00
		.word	0x0007, 0x0000, 0x0004, 0x9500
		.word	0x0008, 0x0000, 0x0FFF, 0x8200
		.word	0x0009, 0x0000, 0x0FF9, 0x1600
		.word	0x000a, 0x0000, 0x0001, 0x5500
		.word	0x000b, 0x0000, 0x0009, 0x9600
		.word	0x000c, 0x0000, 0x0FFD, 0xA400
		.word	0x000d, 0x0000, 0x0FF2, 0xCE00
		.word	0x000e, 0x0000, 0x0004, 0x0600
		.word	0x000f, 0x0000, 0x0011, 0x8C00
		.word	0x0010, 0x0000, 0x0FF9, 0xC200
		.word	0x0011, 0x0000, 0x0FE8, 0xFC00
		.word	0x0012, 0x0000, 0x0009, 0x5B00
		.word	0x0013, 0x0000, 0x001D, 0xA100
		.word	0x0014, 0x0000, 0x0FF2, 0x8A00
		.word	0x0015, 0x0000, 0x0FDA, 0x3B00
		.word	0x0016, 0x0000, 0x0012, 0xF300
		.word	0x0017, 0x0000, 0x002F, 0xB200
		.word	0x0018, 0x0000, 0x0FE5, 0xDC00
		.word	0x0019, 0x0000, 0x0FC3, 0xF300
		.word	0x001a, 0x0000, 0x0023, 0xAF00
		.word	0x001b, 0x0000, 0x004B, 0xB800
		.word	0x001c, 0x0000, 0x0FCF, 0x8E00
		.word	0x001d, 0x0000, 0x0F9F, 0x8E00
		.word	0x001e, 0x0000, 0x0042, 0x0700
		.word	0x001f, 0x0000, 0x007D, 0x9300
		.word	0x0020, 0x0000, 0x0FA4, 0xA700
		.word	0x0021, 0x0000, 0x0F55, 0x3100
		.word	0x0022, 0x0000, 0x0082, 0xA500
		.word	0x0023, 0x0000, 0x00FD, 0x7800
		.word	0x0024, 0x0000, 0x0F39, 0x4100
		.word	0x0025, 0x0000, 0x0E36, 0xD100
		.word	0x0026, 0x0000, 0x0144, 0x6400
		.word	0x0027, 0x0000, 0x05A2, 0x5700
		.word	0x0028, 0x0000, 0x05A2, 0x5700
		.word	0x0029, 0x0000, 0x0144, 0x6400
		.word	0x002a, 0x0000, 0x0E36, 0xD100
		.word	0x002b, 0x0000, 0x0F39, 0x4100
		.word	0x002c, 0x0000, 0x00FD, 0x7800
		.word	0x002d, 0x0000, 0x0082, 0xA500
		.word	0x002e, 0x0000, 0x0F55, 0x3100
		.word	0x002f, 0x0000, 0x0FA4, 0xA700
		.word	0x0030, 0x0000, 0x007D, 0x9300
		.word	0x0031, 0x0000, 0x0042, 0x0700
		.word	0x0032, 0x0000, 0x0F9F, 0x8E00
		.word	0x0033, 0x0000, 0x0FCF, 0x8E00
		.word	0x0034, 0x0000, 0x004B, 0xB800
		.word	0x0035, 0x0000, 0x0023, 0xAF00
		.word	0x0036, 0x0000, 0x0FC3, 0xF300
		.word	0x0037, 0x0000, 0x0FE5, 0xDC00
		.word	0x0038, 0x0000, 0x002F, 0xB200
		.word	0x0039, 0x0000, 0x0012, 0xF300
		.word	0x003a, 0x0000, 0x0FDA, 0x3B00
		.word	0x003b, 0x0000, 0x0FF2, 0x8A00
		.word	0x003c, 0x0000, 0x001D, 0xA100
		.word	0x003d, 0x0000, 0x0009, 0x5B00
		.word	0x003e, 0x0000, 0x0FE8, 0xFC00
		.word	0x003f, 0x0000, 0x0FF9, 0xC200
		.word	0x0040, 0x0000, 0x0011, 0x8C00
		.word	0x0041, 0x0000, 0x0004, 0x0600
		.word	0x0042, 0x0000, 0x0FF2, 0xCE00
		.word	0x0043, 0x0000, 0x0FFD, 0xA400
		.word	0x0044, 0x0000, 0x0009, 0x9600
		.word	0x0045, 0x0000, 0x0001, 0x5500
		.word	0x0046, 0x0000, 0x0FF9, 0x1600
		.word	0x0047, 0x0000, 0x0FFF, 0x8200
		.word	0x0048, 0x0000, 0x0004, 0x9500
		.word	0x0049, 0x0000, 0x0000, 0x3E00
		.word	0x004a, 0x0000, 0x0FFC, 0xBD00
		.word	0x004b, 0x0000, 0x0000, 0x5500
		.word	0x004c, 0x0000, 0x0001, 0x8300
		.word	0x004d, 0x0000, 0x0000, 0x4500
		.word	0x004e, 0x0000, 0x0FFE, 0x3800
		.word	0x004f, 0x0000, 0x0000, 0xE400
		.word	0FFFFH	; End of Table
ad6620_filter_end:


	.end