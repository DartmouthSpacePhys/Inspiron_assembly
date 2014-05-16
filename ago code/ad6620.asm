****
* AD6620 setup functions and tables
***

* History
* 
* v1.0 	3 June 2012	Converted from an .include file to a compilable, sectioned file.
*

	.mmregs
	.def	rsp_clear, rsp_reset, rsp_init, rsp_mstart, rsp_sstart
;	.def	ad6620_soft_reset, ad6620_filter, ad6620_master_run, rsp_setup
	.include "rx-dsp.h"
	.sect	".ad6620"

*
* rsp_reset, rsp_init, rsp_mstart, rsp_sstart
* 	shell functions over rsp_setup
*	

rsp_reset:
	ld	#ad6620_soft_reset, A ; Put AD6620 into reset
	call	rsp_setup
	
	retd
	nop
	nop
	
rsp_init:
	ld	#ad6620_filter,A ; Set up AD6620 filter
	call	rsp_setup
	
	retd
	nop
	nop

rsp_mstart:
	ld	#ad6620_master_run, A	; Start digitizing as master
	call	rsp_setup
	
	retd
	nop
	nop

rsp_sstart:
	ld	#ad6620_slave_run, A	; Start digitizing as slave
	call	rsp_setup
	
	retd
	nop
	nop

	
*
* rsp_clear	Function to clear RCF Data RAM between frames
*

rsp_clear:
	stm		#100000001b, AR3
	nop
	nop
	portw	AR3, (wr_rx+amr)	; Load high and low address registers: 
	stm		#0, AR3
	nop
	nop
	portw	AR3, (wr_rx+lar)	; write to RAM address 0x100, auto-increment
	
	stm		#0xFF-1, BRC
	nop
	nop
	rptb	rsp_clear_loop - 1
	
	portw	AR3, (wr_rx+dr4)
	portw	AR3, (wr_rx+dr3)
	portw	AR3, (wr_rx+dr2)
	portw	AR3, (wr_rx+dr1)
	portw	AR3, (wr_rx+dr0)
	nop

rsp_clear_loop:

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
		.word	 0x303, 0x0001, 0xeb85, 0x3f00  ; NCO Frequency = 500 kHz
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
NCO_500_kHz:
		.word	 0x303, 0x0001, 0xeb85, 0x3f00
		.word	 0FFFFh
NCO_1000_kHz:
        .word    0303h, 0003h, 0D70Ah, 7E00h	; NCO Frequency = 1 MHz
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