	.mmregs
	.global ZERO, BMAR, PREG, DBMR, INDX, ARCR, TREG1
	.global TREG2, CBSR1, CBER1, CBSR2, CBER2
	.text
;
; TMS320C542 Debug Monitor - Translated (and modified) from 'C50 version
;
; Vandiver Electronics
; 741 Chase Road 
; Huntsville, Alabama 35811
;
; Revision History
; 
; Date		Monitor Version/Action
; 23 Dec 2009	1.10: Updated boot-up messages.
; 29 Oct 2006	1.09: Added MASTER/SLAVE indication.
; 17 Sep 2006	1.09: Appended code and table for AD6620 set-up.
; 09 Sep 2006   1.09: Added semicolon terminator to "R" command. This terminator
;		      ends the command and returns the monitor to the ">" 
;		      command prompt. In this way, a file with a list of "R...;"
;		      commands can be sent to the monitor to initialize the
;		      AD6620. Added semicolon terminator to "I", "M", and "O"
;		      commands; updated help messages to reflect changes.
; 08 Sep 2006   1.09: Repaired branch to monitor at application.
; 08 Sep 2006	1.09: No changes to monitor, however, a small application 
;		      appended to assist in FIFO check-out. 
; 06 Sep 2006   1.09: Updates to AD6620 rspmod "R" command. Added "inp1hex"
;		      entry point to inp4hex routine to allow conversion
;		      of a single nybble to the MS nybble of a byte, followed
;		      by entry and conversion of LS nybble. Cleared B before
;		      each call to inp2hex for byte entries. Write to AMR
;		      and LAR forced at each read; read started with "dummy"
;		      read of DR0 to load DR4, DR3, DR2, and DR1 in AD6620.
;		      Refer to page 31 of AD6620 data sheet.
;		      Added "repout" feature to allow repeat of output
;		      function with same data and address as previous output
;		      simply by typing "R" for terminator (no need to type
;		      data or address again).

; 05 Sep 2006	1.08: Removed Iowa application code. Added DIS2HEX routine.
; 04 Sep 2006	1.08: Added "O" command for output to port without
;				immediate read-back. Removed "C" command.
; 01 Sep 2006	1.08:	Updated RSP I/O addresses wr_rx and rd_rx to
;				avoid boot conflict at I/O address E000h/FFFFh.
; 15 Jul 2006	1.08: Coded rspmod routine, to allow interaction with AD6620
; 14 Jul 2006	1.08: Dartmouth University Version for CHARM Rx-DSP
; 11 Oct 2001	1.07: Mods to app: Restructured sync code, moved to top.
; 05 Oct 2001	1.07: Mods to app: Timer value.
; 02 Oct 2001	1.07: Mods to app: Clean-up near end of code.
; 01 Oct 2001	1.07: Mods to app; 4 X 16 "correlator totals"
;		removed; 8 X 16 bagels kept. Bias and minor frame
;		reset counter added to data out.
; 29 Sep 2001	1.07: Mods to app; 8 X 16-bit counters for bagel.
;		4 X 16 counters for correlator totals.
; 27 Sep 2001	1.07: Mods to app; timer interrupt.
; 27 Sep 2001	1.07: Mods to app (re-arranged code for sending data
;		to FIFO ASAP after interrupt; step cycle branching
;		clean-up; sweep DAC code telemetry fixed. Monitor
;		not changed.
; 04 Apr 2001	1.07: Mods to app (major/minor interrupt vectors same,
;		other clean-up, code re-arranged)
; 14 Nov 2000	1.07: Mods for interrupt driven version.
; 11 Nov 2000	1.07: Mods to app section for re-arranged log DACs,
;		so all log DACs are written to together, and all
;		linear DACs are likewise written to together.
; 03 Oct 2000	1.07: Mods to allow timer interrupt to simulate a 
;		minor frame interrupt. 
; 02 Oct 2000	1.07: Monitor combined with test "appcode". Message
;		added to boot-up banner to indicate this. Interrupt
;		vectors for major_int, minor_int defined.
; 01 Oct 2000	1.07: Cleared A and B to zero before call to inp2hex
;		in counter test routine cdisp. This should fix a bug
;		which often caused the counter display to run on
;		rather than stopping at the specified number of words.
;		Also made clearing of A and B the same at the beginning
;		of inp4hex. New start-up code, app branch, PMST init.
; 18 Sep 2000	1.06: Fixed B accumulator loading in inp3hex. First
;		nybble is now loaded, rather than "ored", into B.
; 18 Sep 2000	1.05: Doubled counter test gate time "ngate" to have
;		610 rpt/nop loops, to give a 1 second gate at 40 MHz. 
; 17 Sep 2000	1.04: Added "stlm A,AR2" to store intermediate checksum result
;		during EEPROM programming. Was neglecting to store sum
;		of data bytes previously. EEPROM was getting programmed
;		OK, but checksum was being flagged as being in error
;		(which it was). Some other clean-up, system constants
;		added, and self-modifying code in I/O modify routine
;		simplified.
;
; 14 Sep 2000	1.03: Added 8000h offset to EEPROM write code; lengthened delay.
;		Added carriage-return entry in iomod, modify, display,
;		fill, and cdisp. Should make for better "feel", so it
;		does not seem like the program is "getting away". 
; 13 Sep 2000	1.02: Interrupt vectors, counter display	
; 12 Sep 2000	1.01: Special version with counter test code. Timer interrupt
;		used to control counter gate time.
; 10 Apr 2000	1.00: Replaced pshm/popm instructions in asx, inp4hex, main.
; 24 Mar 2000	Debug of messages, previous mem/I/O.
; 23 Mar 2000	Assembly, first ROMs burned, debug.	
; 22 Mar 2000	Clean-up of code.	
; 21 Mar 2000	Copied from 'C50 Version, MONC55. Used TAP5000
;		translator; hand-modified some parts. Translator
;		tended to use lots of delayed branches and calls,
;		which made for difficult to read code.    
; 24 June 1996  Code design/entry.
; 25 June 1996  Serial Tx (asx) and Rx (asr) routines working.
; 26 June 1996  Routines msgout, asc2hex, hex2asc, inphex, dis4hex, modify.
; 27 June 1996  Routines go, display, fill, and main menu.
; 28 June 1996  Routines load, io, eeprom.
; 02 July 1996  Work on EEPROM routine, installed.
; 18 July 1996  Attempt to add help info and introductory message.
;		I/O and Modify commands with final CR, SPACE, -, or ESC
;		after new data entry.
; 24 Sep  1996  Checksum correction in Load and Eeprom routines- needed to
;		include length, address, and record type in checksum.  
; 25 Sep  1996  Line length counter fix in Load and Eeprom.
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
; Async serial parameters
;
nbits   .set    8 
nstop   .set    2 
fullbit .set    16667		; Number of CLKOUT1 cycles/bit at 2400 baud, 
halfbit .set    8333		; with 40 MHz TCLK
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
	b	major_int	; INT0/SINT0 16
	nop
	nop
;
	b	minor_int	; INT1/SINT1 17
	nop
	nop
;
	b	mon		; INT2/SINT2 18
	nop
	nop
;
	b	timer_int	; TINT/SINT3 19 (just returns)
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
	ssbx    INTM		; Disable interrupts 
	stm	#stack,SP	; Stack pointer to high RAM
	stm	#npmst,PMST	; Set processor mode/status
	rsbx	SXM		; Suppress sign extension 
	nop			; Space for branch to app
	nop

	portr	rd_disc, AR3	; Get discrete bits to AR3
	bitf	AR3,trm_28	; Test for high terminal input	
	bc	appcode,NTC	; Run app if low, monitor if high 
;
; Application code entry point
; 
appent:

	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ld      #version,A	; Start-up message	
	call	msgout
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
;
; Main Loop- Command Interpreter
;
main:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ld      #003Eh,A	; > prompt 
	call	asx
	call	asr		; Get command 
	call	asx		; Echo it 

	stlm	A,AR7		; Save copy 
	sub     #0044h,A,A      ; D... display? 
	cc      display,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #0046h,A,A      ; F... fill? 
	cc      fill,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #0047h,A,A      ; G... go? 
	cc      go,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #0049h,A,A      ; I... I/O? 
	cc      iomod,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #004Ch,A,A      ; L... load? 
	cc      load,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #004Dh,A,A      ; M... modify? 
	cc      modify,AEQ
	ldm	AR7,A

	stlm	A,AR7
	sub     #004Fh,A,A      ; O... output? 
	cc      output,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #0050h,A,A      ; P... program EEPROM? 
	cc      eeprom,AEQ
	ldm	AR7,A

	stlm	A,AR7
	sub     #0052h,A,A      ; R... AD6620 RSP register modify? 
	cc      rspmod,AEQ
	ldm	AR7,A
 
	stlm	A,AR7
	sub     #003Fh,A,A      ; ?... Help? 
	cc      dhelp,AEQ
	ldm	AR7,A
 
	b      main
 
;
;  Software asynchronous serial transmit
;
;  Byte to send must be in low accumulator bits
;
asx:
	stlm	A,AR6		; Preserve byte in Acc	
				; AR5: bit counter 
	or      #0FF00h,A,A     ; Set high 8 bits of Acc to 1 
	rsbx    C		; Startbit = 0 
	stm     #10,AR5		; Bit counter: 1 start + 8 databits + 2 stop 
txbit:
	bc      tx0,NC		; Carry bit = data to send --> xf 
	ssbx    XF		; "1" 
	b      tx
tx0:
	rsbx    XF		; "0" 
tx:
	rpt	#fullbit	; Wait for 1 bit period 
	nop
	ror     A		; Shift next bit into carry 
	banz	txbit,*AR5-	; Repeat for all bits 
	ldm	AR6,A		; Restore byte in Acc 
	ret
;
; Asynchronous serial receive
;
; Received data in Acc upon return
;
asr:
				; AR5: bit counter 
	stm     #7,AR5		; Set to number of data bits -1 
	ld      #0000h,A	; Clear accumulator 
	rsbx	C		; Clear carry bit
wedge:
	bc      wedge,NBIO      ; Wait for start bit edge (BIO* low)
 
edge:	
	rpt	#halfbit	; Wait for middle of start bit 
	nop
	bc      asr,NBIO	; Is start bit still low at middle? 
				; No- go back and look for next start 
sample:
	rpt	#fullbit	; Full bit time wait 
	nop			; 
	bc      rzero,BIO
	or      #0100h,A	; If sample = 1, put 1 into Acc bit 8
rzero:
	ror	A		; Shift sample right, get ready for next
	banz	sample,*AR5-	; All bits ?
	and	#00FFh,A 
	ret			; Received byte in Acc bits 7-0 
;
; Null-terminated string to console
;
; A should have address of message before call,
; which is moved to AR4 within the routine.
; Use like this:
;
;
;       ld     #message,A	; Load starting address of string
;       call    msgout		; Go display it
;       etc
;
msgout:
	stlm	A,AR4		; Use AR4 as pointer 
msg1:
	ldu	*AR4,A		; Get word pointed to by AR4 
	sftl    A,-8,A
	and	#00FFh,A,A	 ;Use low byte 
	bc      msgx,AEQ	; Display until null (0) byte reached 
	call    asx
	ldu     *AR4+,A		; Get word again, inc pointer 
	and     #00FFh,A,A	; Use low byte 
	bc      msgx,AEQ	; Stop on null 
	call	asx
	b	msg1
msgx:
	ret
;
; Display help command list
;
dhelp:
	ld	#help,A
	call	msgout
	ret
;
;
; Load Intel Hex File to RAM
;
load:
	call    asr		; Get character 
	call    asx		; Echo 
	ld      A,0,B		; Save a copy
	sub     #1Bh,A,A	; ESC? (User has taken over link to exit) 
	bc      loadret,AEQ     ; return immediately if ESC 
	ld      B,0,A		; Get copy of character
	sub     #003Ah,A,A      ; Wait for : at start of line 
	bc      load,ANEQ
	ld      #0000h,A	; Clear accumulator 
	ld	A,0,B		; Clear buffer 
	stlm	A,AR2		; Clear checksum 
	call	inp2hex		; Get number of bytes on this line 
	and     #00FFh,A,A      ; Mask to low byte to be safe 
	stlm	A,AR2		; Start checksum 
	stlm	A,AR1		; Save and adjust length counter 
	nop
	nop
	mar	*AR1-		; Use number of bytes - 1 
 
	nop
	nop
	call	inp4hex		; Get destination address 
	stlm    A,AR0		; Put in pointer 
	and     #00FFh,A,A      ; Mask to low byte 
	add     AR2,A		; AR2 holds checksum
	stlm	A,AR2		; Save checksum
	ldm     AR0,A		; Get address again 
	sftl    A,-8,A		; Shift high byte to low byte
	and     #00FFh,A,A      ; Mask to low byte 
	add     AR2,A		; add to checksum, AR2 at 18 
 	stlm	A,AR2		; Save checksum 
	ld      #0000h,A	; Clear acc and buffer 
	ld	A,0,B
	call	inp2hex		; Get record type
  	and     #00FFh,A,A
	ld      A,0,B		; Save a copy 
	add     AR2,A		; add to checksum 
	stlm	A,AR2		; Save checksum 
	ld      B,0,A		; Get record type copy  
	bc      loadhi,AEQ      ; Get line if record type = 00 (data) 
				; Not data 
	sub     #01h,A,A	; EOF? 
	bc      loadex,AEQ      ; Exit if EOF 
	B       load		; Wait for data line otherwise 
loadhi:
	ld      #0000h,A	; Clear acc and buffer 
	ld	A,0,B
	call	inp2hex		; Get data byte 
	and     #00FFh,A,A      ; Make sure higher data is zero 
	ld      A,0,B
	add     AR2,A		; AR2 holds checksum
	stlm	A,AR2
	ld      B,0,A		; Get copy of byte
	sftl    A,+8,A		; Shift to MS position of word
	stl     A,*AR0		; Save high byte to memory, no increment 
				; This also clears LS byte of memory
	banz    loadlo,*AR1-    ; Last byte on line? 
	B       loadeol
 
loadlo:
	ld      #0000h,A	; Clear acc and buffer 
	ld	A,0,B
	call    inp2hex		; Get data byte 
	and     #00FFh,A,A      ; Low byte only 
	ld      A,0,B		; Save a copy
	add     AR2,A		; AR2 holds checksum
	stlm	A,AR2
	ld      B,0,A		; Get copy
	OR      *AR0,A		; OR with shifted byte to build word 
	stl     A,*AR0+		; Save word to memory, inc address 
	banz    loadhi,*AR1-    ; Get next byte if not last 
loadeol:
	ld      #0000h,A	; Clear acc and buffer
	ld	A,0,B
	call   inp2hex		; Get checksum 
	and     #00FFh,A,A
	add     AR2,A		; AR2 holds checksum
;	stlm	A,AR2
	and     #00FFh,A,A      ; Look only at LS byte 
	bc      load,AEQ	; If zero, go get next line 
	ld      #002Ah,A	; Flag error with * 
	call	asx
	ldm     AR2,A		; What do we think checksum is? 
	call	dis4hex
	b       load		; Do next line despite error 
 
loadex:
	ld      #0000h,A	; Clear acc and buffer
	ld	A,0,B  
	call   inp2hex		; Get checksum 
	call    asr		; Get final CR, LF and echo 
	call    asx
	call    asr
	call    asx
loadret:
	ret
;
; Load Intel Hex File to byte-wide data space EEPROM
;
; Note: EEPROM is 8K or 32K X 8. address lines A00 to A12 are connected
; to the 'C542, allowing an 8K portion of EEPROM to be accessed. EEPROM
; address lines A13 and A14 are jumper-selectable. address lines A13,
; A14, and A15 from the 'C542 are decoded so that data memory address
; 8000H is the start of the EEPROM. At boot time, the 'C542 reads I/O
; address 0FFFFH, the contents of which is forced to XX81h by pull-ups
; and pull-downs. The low byte of this word (81H) is the boot routine
; select code, which causes the 'C542 to boot from the 8-bit EEPROM
; starting at data memory address 8000H. The boot loader on the 'C542
; reads the following bytes from the EEPROM:
; Destination (high), the program memory address where the program goes
; Destination (low)
; (Length in words -1) (high)
; (Length in words -1) (low)
; Program bytes
;
; Checksum failure on a given line, flagged by a "*" in the echo
; data, can indicate an erroneous value in the EEPROM found after
; readback, or some error in the incoming data.
;
; The write enable jumper must also be set properly for this to work.   
;
; Hex files should be generated for a base address of 0000h. This
; routine will "OR" 8000h with the addresses included with the HEX
; file so that address 0000h in the HEX file will correspond to
; 8000h in the DSP data memory space.
;
; Note that the EEPROM data appears as one (lower) byte at every
; word address from 8000H to 9FFFH. The upper byte of each word
; appears as FFh.
;
; Register usage:
; AR0: address
; AR1: bytes per line
; AR2: checksum
; Accumulators A and B: Miscellaneous
;
eeprom:
	call	asr		; Get character 
	call    asx		; Echo 
	ld      A,0,B		; Save a copy
	sub     #1Bh,A,A	; ESC? (User has taken over link to exit) 
	bc      eepret,AEQ      ; return immediately if ESC 
	ld      B,0,A		; Get copy of character
	sub     #003Ah,A,A      ; Wait for : at start of line 
	bc      eeprom,ANEQ
	ld	#0000h,A	; Clear accumulator and buffer
	ld	A,0,B
	stlm	A,AR2		; Clear checksum
	call	inp2hex		; Get number of bytes on this line
	and	#00FFh,A,A	; Low byte only 
	stlm	A,AR2		; Start checksum 
	stlm	A,AR1		; Save and adjust length counter
	nop
	nop
	mar	*AR1-		; Use number of bytes - 1
	nop
	nop
	call	inp4hex		; Get destination address
	stlm	A,AR0		; Save to pointer
	and     #00FFh,A,A      ; Get low byte 
	add     AR2,A		; add to checksum 
	stlm	A,AR2		; Save checksum 
	ldm     AR0,A		; Get address again 
	sftl    A,-8,A		; Shift high byte to low byte
	and	#00FFh,A,A	; Mask to low byte
	add	AR2,A		; add to checksum
	stlm	A,AR2		; Save checksum
;
	ldm	AR0,A		; Get address
	or	#8000h,A	; Insert offset (EEPROM decoder base address)
	stlm	A,AR0		; Save modified address for EEPROM write
;
	ld	#0000h,A	; Clear accumulator and buffer
	ld	A,0,B 
	call	inp2hex		; Get record type 
	and	#00FFh,A,A	; Mask to low byte
	ld	A,0,B		; Save a copy 
	add	AR2,A		; add to checksum 
	stlm	A,AR2		; Save checksum 
	ld	B,0,A		; Restore record type 
	bc	eeprdat,AEQ     ; Get line if record type = 00 (data) 
				; Not data 
	sub	#01h,A,A	; EOF? 
	bc	eeprex,AEQ      ; Exit if EOF 
	b	eeprom		; Wait for data line otherwise 
eeprdat:
	ld	#0000h,A	; Clear acc and buffer 
	ld	A,0,B
	call	inp2hex		; Get data byte 
	and	#00FFh,A,A	; Make sure high byte is zero
	stl	A,*AR0		; Save byte to memory 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 
	rpt	#0FFFFh		; 3.2768 ms per repeated NOP at 20 MHz
	nop 

;	ldu     *AR0+,A		; Read back stored byte for check, inc pointer  
	ld	*AR0+,A
	and     #00FFh,A,A
	add     AR2,A		; Add to checksum- which checks EEPROM 
	stlm	A,AR2		; Store intermediate checksum result (1.04 fix)
	banz	eeprdat,*AR1-   ; Last byte on line? 
 
eepreol:
	ld	#0000h,A	; Clear acc and buffer 
	ld	A,0,B
	call	inp2hex		; Get hex file checksum 
	and	#00FFh,A,A	; Mask to low byte
	add	AR2,A		; Add to working sum in AR2
	and	#00FFh,A,A      ; Look only at LS byte 
;	stlm	A,AR2		; Save checksum
	bc	eeprom,AEQ      ; If zero, go get next line 
	ld	#002Ah,A	; Flag error with * 
	call	asx
	ldm	AR2,A		; Get value of checksum, display	
	call	dis4hex
	b	eeprom		; Do next line despite error 
 
eeprex:
	ld	#0000h,A	; Clear acc and buffer  
	ld	A,0,B
	call	inp2hex		; Get EOF-record checksum 
	call	asr		; Get final CR, LF and echo 
	call	asx
	call	asr
	call	asx
eepret:
	ret

;
; Read port and write port machine codes
; 
; portr3  .set    07413h	; Machine code for PORTR address, AR3 
; portw3  .set    07513h	; Machine code for PORTW AR3, address 
;
; Modify I/O space at user-specified address
;
; Simplified "self-modifying code" in version 1.04 - JCV
; Let assembler generate opcodes for portr and portw, then
; routine modifies address word as needed
; Uses:
; AR0: I/O address
; AR1: Points to address word of portr instruction
; AR2: Points to address word of portw instruction
; AR3: Holds data to send to or read from I/O port
;
; Added semicolon terminator 9 Sept. 2006
;
iomod:
;	ld      #aportr3,A      ; Address of portr address, AR3 code 
;	stlm    A,AR1
;	ld      #portr3,A       ; portr address, AR3 code 
;	stl     A,*AR1+		; Store code and point to address word 
	stm	#aportr3,AR1	; Get port read instruction address
	mar	*AR1+		; Point to read port address word
	nop
	nop

;	ld      #aportw3,A      ; Address of portw AR3, address code 
;	stlm    A,AR2
;	ld      #portw3,A       ; portw AR3, address code 
;	stl     A,*AR2+		; Store code and point to address word 
	stm	#aportw3,AR2	; Point to port write instruction address
	mar	*AR2+		; Point to write port address word
	nop
	nop

	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get I/O address 
	stlm    A,AR0		; Save to AR0 for use as pointer 

modio:
	ldm     AR0,A		; Restore I/O address in accumulator 
	stl     A,*AR1		; Save address to input instruction 
	stl     A,*AR2		; Save address to output instruction 
	ld      #0020h,A	; Space over on screen 
	call	asx
aportr3:
	portr	0000h,AR3	; Address is modified as needed
;	nop			; portr address, AR3 self-modifying
;	nop 
	ldm     AR3,A		; Get data at I/O address 
	call	dis4hex		; Display 
	ld      #0020h,A	; Space over 
	call	asx
	call    asr		; Get response 
	ld      A,0,B		; Save copy 
	sub     #000Dh,A,A      ; Carriage return? 
	bc      nextio,AEQ
	ld      B,0,A
	sub     #002Bh,A,A      ; +? 
	bc      nextio,AEQ
	ld      B,0,A
	sub     #002Dh,A,A      ; -? 
	bc      previo,AEQ
	ld      B,0,A
	sub     #0020h,A,A      ; Space? 
	bc      sameio,AEQ
	ld      B,0,A
	sub     #001Bh,A,A      ; Escape? 
	bc      quitio,AEQ
	ld      B,0,A
	sub     #003Bh,A,A	; Semicolon? 
	bc      quitio,AEQ

	ld      B,0,A		; Assume new data 
 
	call	inp3hex		; Echo MS nybble and get 3 remaining nybbles 
	stlm	A,AR3		; AR3 holds output data 
	call	asr		; Get terminator 
	ld	A,0,B		; Save copy
				; Modify port AFTER terminator is typed
aportw3:
	portw	AR3,0000h	; Address is modified as needed
;	nop			; portw AR3, address self modifying 
;	nop 
	
	ld	B,0,A 
	sub	#000Dh,A,A	; Carriage return? 
	bc      nextio,AEQ
	ld      B,0,A
	sub     #002Bh,A,A	; +? 
	bc      nextio,AEQ
	ld      B,0,A
	sub     #002Dh,A,A	; -? 
	bc      previo,AEQ
	ld      B,0,A
	sub     #0020h,A,A	; Space? 
	bc      sameio,AEQ
	ld      B,0,A
	sub     #001Bh,A,A	; Escape? 
	bc      quitio,AEQ
	ld      B,0,A
	sub     #003Bh,A,A	; Semicolon? 
	bc      quitio,AEQ

sameio:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ldm     AR0,A		; Get new address 
	call	dis4hex		; Display address 
	b	modio		; Go get data and display 
nextio:
	mar	*AR0+		; Inc address 
	nop
	nop
	b	sameio		;
previo:
	mar	*AR0-		; Dec address
	nop
	nop
	b	sameio
quitio:
	ret
 
;
; Output to I/O space at user-specified address
; A simplified version of Modify I/O, without read-before-write
;
; New for version 1.08, 4 Sept. 2006
; Added "repout" feature, 1.09, 6 Sept. 2006, to allow
; repeat of output function with same data and address
; as previous output by typing "R" for terminator
; Added semicolon terminator, 9 Sept. 2006
;
; Let assembler generate opcodes for portw, then
; routine modifies address word as needed
; Uses:
; AR0: I/O address
; AR1: Not used
; AR2: Points to address word of portw instruction
; AR3: Holds data to send to I/O port
;

output:

	stm	#aportw4,AR2	; Point to port write instruction address
	mar	*AR2+		; Point to write port address word
	nop
	nop

	ld      #0020h,A	; Space over on screen 
	call    asx
	call    inp4hex		; Get I/O address 
	stlm    A,AR0		; Save to AR0 for use as pointer 

modout:
	ldm     AR0,A		; Restore I/O address in accumulator 
	stl     A,*AR2		; Save address to output instruction 
	ld      #0020h,A	; Space over on screen 
	call	asx
	call	inp4hex		; Get output data 
	stlm	A,AR3		; AR3 holds output data 
trmout:
	call	asr		; Get terminator 
	ld	A,0,B		; Save copy
				; Modify port AFTER terminator is typed
aportw4:
	portw	AR3,0000h	; Address is modified as needed
	
	ld	B,0,A 
	sub	#000Dh,A,A	; Carriage return? 
	bc      nextout,AEQ
	ld      B,0,A
	sub     #002Bh,A,A	; +? 
	bc      nextout,AEQ
	ld      B,0,A
	sub     #002Dh,A,A	; -? 
	bc      prevout,AEQ
	ld      B,0,A
	sub     #0020h,A,A	; Space? 
	bc      sameout,AEQ
	ld      B,0,A
	sub     #0052h,A,A      ; R: Repeat data and address? 
	bc      repout,AEQ
	ld      B,0,A
	sub     #001Bh,A,A	; Escape? 
	bc      quitout,AEQ
	ld      B,0,A
	sub     #003Bh,A,A	; Semicolon? 
	bc      quitout,AEQ

sameout:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ldm     AR0,A		; Get new address 
	call	dis4hex		; Display address 
	b	modout		; Go get output data and display 

repout:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ldm     AR0,A		; Get address 
	call	dis4hex		; Display address 
	ld      #0020h,A	; Space over on screen 
	call	asx
	ldm	AR3,A		; AR3 holds data from previous output
	call	dis4hex
	b	trmout		; Go get terminator 

nextout:
	mar	*AR0+		; Inc address 
	nop
	nop
	b	sameout		;
prevout:
	mar	*AR0-		; Dec address
	nop
	nop
	b	sameout
quitout:
	ret
;
; Modify data memory at user-specified address
;
; Added semicolon terminator 9 Sept. 2006
;
modify:
	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get address 
	stlm	A,AR0		; Save to AR0 for use as pointer 
moddata:
	ld      #0020h,A	; Space over on screen 
	call	asx
	ldu     *AR0,A		; Get data at address 
	call	dis4hex		; Display 
	ld      #0020h,A	; Space over 
	call	asx
	call    asr		; Get response 
	ld      A,0,B		; Save copy 
	sub     #000Dh,A,A      ; Carriage return? 
	bc      next,AEQ
	ld      B,0,A
	sub     #002Bh,A,A      ; +? 
	bc      next,AEQ
	ld      B,0,A
	sub     #002Dh,A,A      ; -? 
	bc      prev,AEQ
	ld      B,0,A
	sub     #0020h,A,A      ; Space? 
	bc      same,AEQ
	ld      B,0,A
	sub     #001Bh,A,A      ; Escape? 
	bc      quit,AEQ
	ld      B,0,A
	sub     #003Bh,A,A      ; Semicolon? 
	bc      quit,AEQ

	ld      B,0,A		; Assume new data 
	call	inp3hex		; Echo MS nybble and get 3 remaining nybbles 
	stlm	A,AR3		; AR3 holds new data 


	call	asr		; Get terminator 
	ld      A,0,B		; Save copy 

	ldm	AR3,A		; Get new data
	stl     A,*AR0		; Save data at address AFTER terminator is typed 

	ld	B,0,A
	sub     #000Dh,A,A      ; Carriage return? 
	bc      next,AEQ
	ld      B,0,A
	sub     #002Bh,A,A      ; +? 
	bc      next,AEQ
	ld      B,0,A
	sub     #002Dh,A,A      ; -? 
	bc      prev,AEQ
	ld      B,0,A
	sub     #0020h,A,A      ; Space? 
	bc      same,AEQ
	ld      B,0,A
	sub     #001Bh,A,A      ; Escape? 
	bc      quit,AEQ
	ld      B,0,A
	sub     #003Bh,A,A      ; Semicolon? 
	bc      quit,AEQ

same:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ldm     AR0,A		; Get new address 
	call	dis4hex		; Display address 
	b       moddata		; Go get data and display 
				; Previous address 
next:
	mar	*AR0+		; Go to next address
	nop
	nop  
	b       same		; 
prev:
	mar	*AR0-		; Go to previous address
	nop
	nop  
	b       same		;
quit:
	ret
;
; Go execute at user-specified address
; ret instruction in target code will return to monitor
; Uses AR4 for temporary storage
;
go:
	ld	#0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get address 
	stlm	A,AR4		; Save copy 
	ld      #0020h,A	; Space over 
	call	asx
	call    asr		; Get response 
	sub     #000Dh,A,A      ; Carriage return? 
	bc      launch,AEQ	; Launch code at address specified
	ret			; Any other key- return to main 
launch:
	ldm	AR4,A		; Restore accumulator 
	bacc	A		; Branch to address in accumulator 
;
; Display memory
;
; Uses AR0 to index through memory
;      AR1 to limit word count
;      AR2 to control number of words per line displayed
;
display:
	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get address 
	stlm	A,AR0		; Save to pointer 
	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get number of words 
	stlm	A,AR1		; Save to word counter 
	nop
	nop
	mar	*AR1-		; Use word count -1 for loop control 
	nop
	nop

	call    asr		; Get terminator 
	sub     #000Dh,A,A      ; Carriage return? 
	bc      line,AEQ	; Return typed- proceed with display
	ret			; Any other key- return to main 

line:
	ld      #000Dh,A	; New line 
	call   asx
	ld      #000Ah,A
	call   asx
	ld	#0007h,A	; 8 words per line
	stlm	A,AR2		; Save to line counter
	ldm	AR0,A		; Get address
	call	dis4hex		; Display at beginning of line 
	ld      #0020h,A	; Space over on screen 
	call	asx
	ld      #0020h,A	; Space over on screen 
	call	asx
nword:
	ldu     *AR0+,A		; Get data at address, inc address 
	call	dis4hex		; Display
	ld      #0020h,A	; Space over 
	call	asx
	banz    more,*AR1-      ; All words done? 
	b       done
more:
	banz    nword,*AR2-     ; Get next word if not EOL 
	b       line		; Start new line if at EOL 
done:
	ret
;
; Fill memory with word pattern
;
fill:
	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get address 
	stlm	A,AR0		; Save to pointer 
	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get number of words 
	stlm	A,AR1		; Save to word counter
	nop
	nop
	mar	*AR1-		; Use word count -1 for loop control 
	nop
	nop
	ld      #0020h,A	; Space over on screen 
	call	asx
	call	inp4hex		; Get fill pattern
	stlm	A,AR2		; Save fill pattern

	call    asr		; Get terminator 
	sub     #000Dh,A,A      ; Carriage return? 
	bc      fillp,AEQ	; Return typed- proceed with fill
	ret			; Any other key- return to main 

fillp:	
	ldm	AR2,A		; Restore fill pattern 
fill1:
	stl	A,*AR0+		; Store fill word at (AR0), increment AR0,
	banz	fill1,*AR1-     ; and loop until zero 
	ret
;
; Get 4 up to ASCII characters from serial port, build word in Acc
; Entry points for situation where one character is already
; entered, or for 2 characters only also provided
; Note: had trouble with [or A,shift,B] so separated
; shift and or operations.
;
; Be sure to clear accumulators A and B before calling 
; inp3hex, inp2hex, or inp1hex.
; 
inp4hex:
	ld      #0000h,A	; Clear accumulator
	ld	A,0,B		; and buffer 
	rsbx	C 		; Carry bit
	call	asr		; Get character 
inp3hex:
	call	asx		; Echo 
	call    asc2hex		; Convert to nybble 
;	or	A,B		; Shift and store 
	ld	A,B		; V1.06 fix- JCV (forces B = A, since B = ?
	sfta	B,+4,B		; upon entry)
inp3tst:
	call    asr		; Get character 
	call    asx		; Echo 
	call    asc2hex		; Convert to nybble 
	or	A,B		; Shift and store 
	sfta	B,+4,B
inp2hex:			; Enter here to input 2 characters
	call    asr		; Get character 
inp1hex:			; Enter here, already data in A, with B clear
	call    asx		; Echo 
	call    asc2hex		; Convert to nybble
	or	A,B		; Shift and store 
	sfta	B,+4,B 
	call	asr		; Get character 
	call	asx		; Echo
	call    asc2hex		; Convert to nybble 
;	and	#000Fh,A,A
	or      B,A		; Store final result in A for return 
; Test
;	call	dis4hex

	ret
;
; Convert data in Acc to 4 ASCII characters and transmit on serial link
; call with data in Acc
;
dis4hex:
	ld	A,0,B		; Store a copy of the word in B
	sftl	A,-12,A		; JCV
	call    hex2asc		; Convert MS nybble to ASCII 
	call    asx		; Serial transmit 

	ld      B,-8,A		; Get copy, shift to next nybble 
	call    hex2asc		; Convert next nybble to ASCII 
	call    asx		; Serial transmit 

	ld	B,-4,A		; Get copy, shift to next nybble 
	call    hex2asc		; Convert next nybble to ASCII 
	call    asx		; Serial transmit 

	ld	B,0,A		; Get copy 
	call	hex2asc		; Convert LS nybble to ASCII 
	call    asx		; Serial transmit
 	ld	B,0,A		; Restore accumulator A

	ret

;
; Convert low byte in Acc to 2 ASCII characters and transmit on serial link
; call with data in Acc
;
dis2hex:
	ld	A,0,B		; Store a copy of the word in B

	ld	B,-4,A		; Get copy, shift to next nybble 
	call    hex2asc		; Convert next nybble to ASCII 
	call    asx		; Serial transmit 

	ld	B,0,A		; Get copy 
	call	hex2asc		; Convert LS nybble to ASCII 
	call    asx		; Serial transmit
 	ld	B,0,A		; Restore accumulator A

	ret
;
; Convert low nybble in Acc to ASCII character (0-F)
;
hex2asc:
	and     #000Fh,A,A      ; Mask to low nybble 
	sub     #9,A,A
	bc      hex21,AGT       ; Go fix values > 9 
	add     #039h,A,A       ; 9 ASCII 
	ret
hex21:
	add     #040h,A,A       ; @ = A - 1 
	ret
;
; Convert ASCII character in Acc to binary in low nybble
;
asc2hex:
	sub     #039h,A,A       ; subtract ASCII 9 character offset    
	bc      asc21,ALEQ      ; If result <= 0, must be in range 0..9 
				; ASCII A..F - ASCII 9 = 8..13, make 10..15
	add     #2,A,A
	and     #000Fh,A,A      ; Mask to 4 bits 
	ret
asc21:
				; ASCII 0..9 - 9 = -9..0, make 0..9
	add     #9,A,A
	and     #000Fh,A,A      ; Mask to 4 bits 
	ret
;
; Read/Modify RSP (AD6620) Registers
;
; This routine is unique to the Dartmouth monitor. The basic idea is to make
; the AD6620 chip registers appear as a "wide" (40 bit) memory words with addresses
; from 0000 to 030D hex, with a command structure similar to Modify. The user types:
;
; R aaaa dddddddddd (data, carriage return, +, -, space, escape, semicolon)
; Carriage return or + displays next address, data
; - displays previos address, data
; Space bar repeats read of data at same address (use to watch for changes)
; Escape or semicolon terminates the command
; Entering data (0-9, A-F) followed by terminator modifies register
; Semicolon allows for automated upload of text file for AD6620 set-up
; This routine built from earlier "iomod" code
; Does not use "self-modifying code", since AD6620 RSP occupies a fixed block
; of 8 DSP I/O addresses
;
; Uses:
; AR0: I/O address
; AR3: Holds data to send to or read from I/O port
;

rspmod:

	ld      #0020h,A	; Space over on screen 
	call	asx
	call    inp4hex		; Get RSP register address 
	stlm    A,AR0		; Save to AR0 for later use 
;
; Transfer RSP register address bytes to AD6620 high and low address registers
;
rsp_modio:
	ldm     AR0,A		; Restore I/O address in accumulator 
	sftl	A,-8,A		; Shift high byte to low byte
	and	#0003h,A,A	; Mask high byte to 2 LSBs (avoid reserved bits
				; and do not auto-increment for now)
	stlm	A,AR3		; Move to AR3 for portw
	portw AR3,wr_rx+amr	; Write to high address register
	ldm	AR0,A		; Get RSP register address
	and	#00FFh,A,A	; Mask to low byte only (actually hardware
				; only uses bits 7:0 of data bus, should not
				; need to mask)
	stlm	A,AR3
	portw AR3,wr_rx+lar	; Write to low address register

	ld      #0020h,A	; Space over on screen 
	call	asx
rsp_aportr3:
	portr	rd_rx+dr0,AR3	; Get LS data byte of 40 bit word, no display
				; This forces loading of higher bytes to AD6620
				; registers dr4, dr3, dr2, dr1
	portr	rd_rx+dr4,AR3	; Get MS data byte of 40 bit word
	ldm     AR3,A		; Get data at I/O address 
	call	dis2hex		; Display
	portr	rd_rx+dr3,AR3	; Get 4th data byte of 40 bit word
	ldm     AR3,A		; Get data at I/O address 
	call	dis2hex		; Display
	portr	rd_rx+dr2,AR3	; Get 3rd data byte of 40 bit word
	ldm     AR3,A		; Get data at I/O address 
	call	dis2hex		; Display
	portr	rd_rx+dr1,AR3	; Get 2nd data byte of 40 bit word
	ldm     AR3,A		; Get data at I/O address 
	call	dis2hex		; Display
	portr	rd_rx+dr0,AR3	; Get LS data byte of 40 bit word
	ldm     AR3,A		; Get data at I/O address 
	call	dis2hex		; Display
	ld      #0020h,A	; Space over 
	call	asx
	call    asr		; Get response 
	ld      A,0,B		; Save copy 
	sub     #000Dh,A,A      ; Carriage return? 
	bc      rsp_nextio,AEQ
	ld      B,0,A
	sub     #002Bh,A,A      ; +? 
	bc      rsp_nextio,AEQ
	ld      B,0,A
	sub     #002Dh,A,A      ; -? 
	bc      rsp_previo,AEQ
	ld      B,0,A
	sub     #0020h,A,A      ; Space? 
	bc      rsp_sameio,AEQ
	ld      B,0,A
	sub     #001Bh,A,A      ; Escape? 
	bc      rsp_quitio,AEQ
	ld      B,0,A
	sub     #003Bh,A,A	; Semicolon? 
	bc      rsp_quitio,AEQ

	ld      B,0,A		; Assume new data, put back into Acc 
;
; Get remaining nybbles of new data and store to AD6620 Data Registers 
;
	ld      #0000h,B	; Clear B 
	call	inp1hex		; Echo MS nybble in A and get 1 remaining nybble 
	stlm	A,AR3		; AR3 holds output data
	portw	AR3,wr_rx+dr4	; Store to AD6620 MS data byte register
	ld      #0000h,B	; Clear B 
	call	inp2hex		; Get next byte
	stlm	A,AR3
	portw	AR3,wr_rx+dr3
	ld      #0000h,B	; Clear B 
	call	inp2hex		; Get next byte
	stlm	A,AR3
	portw	AR3,wr_rx+dr2
	ld      #0000h,B	; Clear B 
	call	inp2hex		; Get next byte
	stlm	A,AR3
	portw	AR3,wr_rx+dr1
	ld      #0000h,B	; Clear B 
	call	inp2hex		; Get LS byte
	stlm	A, AR3		; Save for subsequent output port write
 
	call	asr		; Get terminator 
	ld	A,0,B		; Save copy
				; Modify AD6620 dr0 register AFTER terminator is typed
				; Note that write to dr0 causes AD6620 to transfer all 5 
				; data bytes to internal data address
rsp_aportw3:
	portw	AR3,wr_rx+dr0	; Address for RSP LS data byte
	
	ld	B,0,A	 	; Retrieve terminator character
	sub	#000Dh,A,A	; Carriage return? 
	bc      rsp_nextio,AEQ
	ld      B,0,A
	sub     #002Bh,A,A	; +? 
	bc      rsp_nextio,AEQ
	ld      B,0,A
	sub     #002Dh,A,A	; -? 
	bc      rsp_previo,AEQ
	ld      B,0,A
	sub     #0020h,A,A	; Space? 
	bc      rsp_sameio,AEQ
	ld      B,0,A
	sub     #001Bh,A,A	; Escape? 
	bc      rsp_quitio,AEQ
	ld      B,0,A
	sub     #003Bh,A,A	; Semicolon? 
	bc      rsp_quitio,AEQ
rsp_sameio:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx
	ldm     AR0,A		; Get new address 
	call	dis4hex		; Display address 
	b	rsp_modio	; Go get data and display 
rsp_nextio:
	mar	*AR0+		; Inc address 
	nop
	nop
	b	rsp_sameio	;
rsp_previo:
	mar	*AR0-		; Dec address
	nop
	nop
	b	rsp_sameio
rsp_quitio:
	ret
;
; Help strings/messages
;
; When modifying the pstrings, be sure to keep
; the length an even number of characters- pad
; with blanks as needed. If not, the assembler
; will fill an unused byte with a null, and this
; will terminate the message display early.
;

version:
	.word	0D0Ah
	.pstring "Vandiver Electronics TMS320C542 Monitor "
	.word	0D0Ah
	.pstring "Version 1.10, Dartmouth CHARM Rx-DSP, 23 December 2009"
	.word	0D0Ah
	.pstring "MASTER, 23 December 2009"
	.word	0D0Ah
help:
	.word	0D0Ah
	.pstring "Command             Description "
	.word 	0D0Ah
	.pstring "?                   Display command list"
	.word	0D0Ah
	.pstring "Daaaa nnnn          Display nnnn words starting at aaaa "
	.word	0D0Ah
	.pstring "Gaaaa               Go execute from address aaaa"
	.word	0D0Ah
	.pstring "Fxxxx yyyy zzzz     Fill memory from xxxx to yyyy with zzzz "
	.word	0D0Ah
	.pstring "Ipppp dddd xxxx     I/O port read/modify (see Modify below) "
	.word	0D0Ah	
	.pstring "L                   Load Intel Hex file "
	.word	0D0Ah
	.pstring "Maaaa dddd xxxx     Modify memory at address aaaa "
	.word	0D0Ah
	.pstring "                    dddd = displayed data, xxxx = entered "
	.word	0D0Ah
	.pstring "                    data (option), or one of the following: "
	.word	0D0Ah
	.pstring "                    ret, +: next, -: previous, ESC, semicolon: end M command"
	.word	0D0Ah
	.pstring "Oaaaa dddd          Output data to address aaaa "
	.word	0D0Ah
	.pstring "                    dddd = entered data, type R to repeat address/data, or: "
	.word	0D0Ah
	.pstring "                    ret, +: next, -: previous, ESC, semicolon: end O command"
	.word	0D0Ah
	.pstring "P                   Program EEPROM with Intel Hex file"
	.word	0D0Ah
	.pstring "Raaaa d40 x40       RSP register read/modify"
	.word	0D0Ah
	.pstring "                    d40 = displayed 40 bit data, x40 = entered  "
	.word	0D0Ah
	.pstring "                    40 bit data data (option), or one of the following: "
	.word	0D0Ah
	.pstring "                    ret, +: next, -: previous, ESC, semicolon: end R command"
	.word	0D0Ah,0000h

;*****************************************************************************
;
; Dartmouth University CHARM Rx-DSP Program
;
; Written by: James C. Vandiver
;
; Vandiver Electronics
; 741 Chase Road 
; Huntsville, Alabama 35811
;
; (256) 851-7712
;
; 
;
; Revision History
; 
; Date        Version/Action
; 23 Dec 2009 M11: Changed NCO center frequency to 2.67 MHz per Dartmouth
;                  request.
; 25 Mar 2009 M10: As received from Dartmouth on 23 December 2009.
; 30 Oct 2006 M09: Major Frame Interrupt State machine mods. Forced reset
;                  of both Rx and TLM FIFOs in state 0. This way, the
;                  DSP does not wait for the TLM EFO flag- it forces the
;                  empty condition, then fills the FIFO. Added state 3 to
;                  be sure that TLM FIFO has time to empty out before starting
;                  next sequence. Updated comments.  
; 29 Oct 2006 M08: Slave code to reset TLM FIFO added (but commented out).
;                  Minor comment updates.
; 29 Oct 2006 M07: Updated interrupt state machine; added State 2 code
;                  to wait until end of sequence before going back
;                  to look at TLM FIFO empty flag in state 0.
;                  Removed one NOP from rx_loop timing. 
; 29 Oct 2006 M06: Cleared registers after call to rx_setup, in order to
;                  have major frame and sequence counters start at 0.
;                  Adjusted rx_loop time delay. 
; 29 Oct 2006 M05: Loaded filter from m4510.xls. Also added watchdog strobe.
; 28 Oct 2006 M04: Updated Rx FIFO read loop.
; 28 Oct 2006 T04: Updated words/frame from 160 to 400, number of minor
;                  frames per major from 40 to 6. Updated iq_len to 200
;                  words (1/2 minor frame). Updated acq_seq length from
;                  9600 to 2400 words (1 major frame). 
; 27 Oct 2006 T03: Code to send headers and a counter, not real receiver data.
;                  Lines commented out with ";test".
; 24 Oct 2006 03: Fixed nco_loop exit condition.
; 18 Oct 2006 02: Fixed major frame counter ms word branch in interrupt
;             code (was branching back to "switch" instead of skipping
;             ms word increment- added label skip_major_ms). Fixed branch
;             to detect end of static header near "static". 
;
; 04 Oct 2006 Editing; clarified register usage for interrupt versus
;             main code; Master/Slave differences; acq_seq and lsb_sel
;             handling. First assembly.
; 03 Oct 2006 First try appended to Monitor
; 02 Oct 2006 Continued editing
; 16 Sep 2006 Continued editing
; 09 Sep 2006 Copied over from Iowa RACBE16, began editing.
;
;*****************************************************************************
;
; System-Specific Constants: Also see monitor section
;
;
; Timer control constants (for test only)
;
ntddr	.set	0		; Timer prescaler load value ("divide by 1")
				; See timer value calculations below
ntss	.set	16		; TSS (timer stop) bit in TCR
nload	.set	32		; TRB (timer reload bit) in TCR
nprd	.set	2399		; Minor frame test (60 us / 25 ns)/(ntddr+1)-1
;
nwait	.set	1599		; (40 us / 25 ns)/(ntddr+1)-1
;
; Scratchpad RAM addresses
; 
;state:	.set	60h		; Major frame interrupt routine state
;
; Constants
;
major	.set	41		; Major frames per Rx cycle (65536/1600)
minor	.set	4		; 4 minor frames per major frame
word	.set	400		; 400 words per minor frame
depth	.set	0FFFFh	; FIFO depth (65636) - 1.
iq_len .set 200		; Number of words before I/Q off, LSB on (1/2 minor frame)
                        ; Also used on slave to set length of acq_seq_out
acq_seq_len .set 1600   ; For possible use on Slave, number of words for acq_seq high
                        ; mainly for debug (= length of major frame)
;
; Discrete Outputs (at wr_disc)
;
par_tm_en	.set	1	; Parallel telemetry enable (active low)
lsb_sel	.set	2	; LSB/I_Q select, low for I_Q
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
;
; Interrupt flag bit masks: TMS320C542 nomenclature
;
int_0	.set	0001h		; Interrupt 0 (major)
int_1	.set	0002h		; Interrupt 1 (minor)
int_2	.set	0004h		; Interrupt 2 (word- not used- boot-up issues)
int_t	.set	0008h		; Timer (for test purposes)
;
; Initialization
;
appcode:
;	stm	#0,state	; Clear interrupt routine state
	stm	#0,AR0		; Clear auxilliary register 0
	portw	AR0,wr_rs_rx	; Reset AD6620 RSP
	portw	AR0,wr_disc	; Enable parallel TLM drivers, I_Q out
	portw	AR0,wr_dog	; Strobe watchdog timer
	portr	rs_fifo,AR0	; Clear TLM FIFO
	portr	rs_rx_fifo,AR0	; Clear Rx FIFO
;
; Set up AD6620 from table
;
	ld	#ad6620_filter,A ; Set up AD6620 filter
	call	rsp_setup

	stm	#0,AR0	; Clear auxilliary registers
	stm	#0,AR1
	stm	#0,AR2
	stm	#0,AR3
	stm	#0,AR4
	stm	#0,AR5
	stm	#0,AR6
	stm	#0,AR7

;
; Test: Set up timer for 960us "minor frame" interrupts
;
;	stm	#ntss,TCR	; Stop timer, load prescaler
;	stm	#nprd,PRD	; Load timer period register
;	stm	#(nload+ntddr),TCR	; Reset and start timer
;
; Flight: Use external interrupt signals to control code
; Test: Use timer to simulate minor frame interrupts
;
	stm	#0FFh,IFR	; Clear any pending interrupts
;	stm	#07h,IMR	; ATII Enable MAJOR, MINOR, and WORD interrupts
;	stm	#03h,IMR	; RACE, APEX: Enable MAJOR and MINOR interrupts
;*	stm	#08h,IMR	;*TEST: Enable timer interrupts
	stm	#01h,IMR	; CHARM: Enable MAJOR interrupts

	rsbx	INTM		; Enable interrupts
;  
; Auxilliary Register Use            Main      Interrupt     
; AR0: General purpose I/O           R/W       R/W   	
; AR1: General purpose index, main   R/W       not used 
; AR2: TLM sequence word counter     R/W       R
; AR3: Interrupt state               R         R/W 
; AR4: Major frame count, LS         R/W       R
; AR5: Major frame count, MS         R/W       R
; AR6: TLM Sequence count, LS        R/W       not used
; AR7: TLM Sequence count, MS        R/W       not used
; A: Accumulator                     R/W       not used 
; B: Accumulator                     not used  R/W
;	
; Note- only AR0 is R/W in both interrupt and main, and must
; be saved on the stack during interrupts
;
; As of version M09, Master resets both the Rx and TLM fifos on
; a  major frame interrupt (State 0). The Rx FIFO reset signal
; is sent to the Slave Rx FIFO over a signal wire (both Master and Slave
; Rx FIFOs are reset at the same time). The Master also sends the
; acq_seq_out signal to the Slave and to the telemetry system to
; denote the start of acquisition. 
; 
; Master begins to send header and receiver data once State 1 is
; entered (this is sent to the main-line code by AR3, the interrupt
; state register).
;
; Master clears acq_seq_out on next major frame interrupt, and transitions
; from state 1 to state 2.
;
; Slave monitors acq_seq_in discrete bit, then clears the TLM FIFO
; and begins to send header and read receiver data when acq_seq_in
; goes high.
;
; Slave sets its own acq_seq_out high just before header transmission
; starts, then resets after iq_len words sent.
; 
; For both Master and Slave, lsb_sel bit is initially low to send
; I/Q bits, then set high after 200 words are sent (includes header
; + 175 I/Q data words). Remaining data has true LSB from AD6620.
;
; Sequence length is FIFO "depth" (65535) words long. The State machine
; looks at the word count, maintained in AR2, to determine when to 
; transition from State 2 to State 3.
;
; State 3 is an "idle" state, allowing 1 Major frame for the TLM
; FIFO to become empty.
;
; Header Format
;  16 words fixed sequence "Dartmouth College Master Rx-DSP " or
;                         "Dartmouth College Slave Rx-DSP  "
;   2 words sequence count
;   2 words major frame count
;   1 word discrete
;   4 words NCO control (denotes band center)
; 175 words I/Q data, with LSB for I = 1, Q = 0  
;
; After header, data with true LSB starts, continuing established
; I/Q alternating pattern
; 
;
; Wait for interrupts, check state
;

wait:
;
; Master: Wait for state change for interrupt routine
;
	cmpm	AR3,#1	; State = 1: TLM FIFO has been reset, so
				; transfer data to TLM
;
; Slave: Wait for acq_seq_in to go high
;
;S	portr	rd_disc,AR0	; Get discrete input bits
;S	ldm	AR0,A
;S	and	#acq_seq_in,A	; Mask to acquiring sequence input from Master
;S	stlm	A,AR0
;S	cmpm	AR0,#acq_seq_in	; See if Master has set acq_seq
				; If zero, wait 

	bcd	wait,NTC	; Delayed branch followed by 2 nops-
	nop			; Interruptible code
	nop
;
; Slave: Turn on acq_seq_out, keep lsb_sel low (I/Q bit out) clear TLM FIFO
;
;S	stm	#acq_seq_out, AR0	; Discrete outputs: lsb_sel low, acq_seq_out high
;S	portw	AR0,wr_disc	;
;S	portr	rs_fifo,AR0		; Reset TLM FIFO

;
; Static header transmission
;
	stm	#0,AR2		; Zero TLM sequence word count
	stm	#static_header,AR1	; Point to static header words
static:
	ld	*AR1+,A		; Get a word, point to next
	stlm	A,AR0		; Check for end of static header
	cmpm	AR0,#0		; Null terminator?
	bc	static_x,TC		; If terminator, end static header
	portw	AR0,wr_out		; Write to telemetry
	mar	*AR2+		; Keep word count
	b	static
static_x:
;
; Dynamic header words
;
	ldm	AR7,A		; Get MS word of TLM sequence count
	stlm	A,AR0
	portw	AR0,wr_out	; Write to telemetry FIFO
	mar	*AR2+
	ldm	AR6,A		; Get LS word of TLM sequence count
	stlm	A,AR0
	portw	AR0,wr_out	; Write to telemetry FIFO
	mar	*AR2+

	ldm	AR5,A		; Get MS word of major frame count
	stlm	A,AR0
	portw	AR0,wr_out	; Write to telemetry FIFO
	mar	*AR2+
	ldm	AR4,A		; Get LS word of major frame count
	stlm	A,AR0
	portw	AR0,wr_out	; Write to telemetry FIFO
	mar	*AR2+
;
; Discrete inputs
;
	nop
	portr	rd_disc,AR0	; Get discrete input bits
	nop
	portw	AR0,wr_out	; Write to telemetry FIFO 
	mar	*AR2+
;
; Include 4 NCO Control words
;
; Note: If we decide to use several NCO frequencies, this code should
; be updated to "grab" the active NCO control words
;
; 23 Dec 2009 changed to 2.67 MHz
;
	stm     #NCO_2670_kHz,AR1 ; Use AR1 as index to NCO words 
nco_loop:
	cmpm	AR1,#NCO_2670_kHz+4	; Is this the end of the table?
					; 24 Oct JCV took out "*" before AR1 above
	bc	nco_loopx,TC	; Quit if at end	
	ld	*AR1+,A		; Get table word: AD6620 address
	stlm	A,AR0		; Move to AR0 for output
	portw	AR0, wr_out
	mar	*AR2+		; Keep count of words sent
	b	nco_loop
nco_loopx:
;
; Receiver data loop- revised 28 October 2006 JCV
; Cycle times for instructions shown in []
; I/O instructions have 7 wait states (default)
; DSP has 25 ns clock cycle
; Loop time goal is 1.5 usec < t < 1.6 usec with typical branches
; 1.55 usec is 62 clock cycles
; lsb_skip branch is false once per sequence
;
rx_loop:

	portr	rd_rx_out,AR0        ; [2+7] Get receiver data
	portw	AR0,wr_out           ; [2+7] Write to TLM
;test	portw AR2,wr_out           ; [2+7] Word count to TLM for test only- JCV 28 Oct. 2006
;
; Repeated nop for loop delay adjust
;
	ssbx	XF                   ; [1]Use XF to check rx_loop period and delay time
	rpt	#31                  ; [1+ #N*1]...Add (1 + 31) clock cycles
	nop                        ; Nop uses 1 cycle, repeated by above #N
	rsbx	XF                   ; [1]Note: If ssbx/rsbx removed later, add 2 to #N 

	mar	*AR2+                ; [1] Keep word count

	cmpm	AR2,#iq_len          ; [2] Send first 1/2 minor frame with I/Q bit
	bc	lsb_skip,NTC         ; [5 true (typ), 3 false] 
	stm	#(lsb_sel+acq_seq_out), AR0	; [2] Master: lsb_sel, acq_seq_out high
;S	stm	#(lsb_sel), AR0	; [2] Slave: lsb_sel high
	portw	AR0,wr_disc          ; [2+7] LSB_SEL = 1 => true LS bit
	
lsb_skip:
;
; Slave (optional) - turn off acq_seq here based on number of words sent
; Must adjust timing above if this is used
;
;S	cmpm	AR2,#acq_seq_len     ; [2] See if time to turn off acq_seq
;S	bc	acq_skip,NTC         ; [5 true (typ), 3 false]
;S	stm	#lsb_sel, AR0        ; [2] Turn off acq_seq, but keep lsb_sel high
;S	portw	AR0,wr_disc          ; [2+7]
acq_skip:
;
; Both Master and Slave- check # of words sent, end sequence if max
;
	cmpm	AR2,#depth	;[2] Compare to max word count for sequence
	bc	rx_loop,NTC ;[5 true (typ) 3 false] 
;
; Sequence counter (32 bits, using AR6 and AR7)
;
	mar	*AR6+		; Increment sequence count
	cmpm	AR6,#0		; Has count rolled over?
	bc	skip_ms, NTC
	mar	*AR7+		; Increment upper word of sequence count
skip_ms:
;
; Strobe watchdog- once per sequence
; Note that JP30 hardware jumper must be installed to use this...
; If JP30 is installed for flight, it must be removed whenever the
; monitor is used (else there will be repeated resets)
;
	stm	#0, AR0        ; Data is not used- just the wr_dog strobe
	portw	AR0,wr_dog     ; Strobe the watchdog

	bd	wait		; Delayed branch, followed by 2 nops,
	nop			; interruptible code
	nop
;
; Timer interrupt 
;
timer_int:
;
; Minor frame entry point
;
minor_int:
;
; Major Frame Entry Point
;
; Covention: Use accumulator B in interrupt code only
; Save AR0 on stack, restore at exit

major_int:
;	ssbx	XF		; Use XF to check interrupt time
	pshm	AR0		; Save AR0 contents for use in main
;
; Slave code: Just count frames and return- state machine bypassed
;
;S	b	major_x
;
; Master- state selection
;
switch:
	cmpm	AR3,#0		; State 0: Clear Rx and TLM FIFOs, acq_seq out
	bc	start_of_seq,TC	; 
	cmpm	AR3,#1		; State 1: Turn off Acq_Seq bit
	bc	acq_seq_off,TC
	cmpm	AR3,#2		; State 2: Wait for end of sequence (AR2 = depth)
	bc	end_of_seq,TC
	cmpm	AR3,#3		; State 3: Allow TLM FIFO to empty
	bc	tlm_empty,TC
	stm	#0,AR3		; Invalid state: Force state 0
;	portr	rs_fifo,AR0		; Reset TLM FIFO
	b	major_x		; Go wait for next major frame

;
; State 0: Clear the FIFOs
;
start_of_seq:
	portr	rs_rx_fifo,AR0    ; Reset Rx FIFO- also sent by wire to Slave
				      ; THIS is where a sampling sequence begins

	stm	#acq_seq_out, AR0 ; Discrete outputs: acq_seq_out- wire to Slave
	portw	AR0,wr_disc       ; Also, lsb_sel = 0 => I/Q bit
	nop

	portr 	rs_fifo,AR0       ; Reset the TLM FIFO
	stm	#1,AR3            ; Set interrupt state to 1

	b	major_x
;
; State 1: Acquiring Sequence Bit (acq_seq_out) off, lsb_sel on
;
acq_seq_off:
	stm	#lsb_sel, AR0     ; Discrete outputs: acq_seq_out low to Slave
	portw	AR0,wr_disc       ; lsb_sel = 1 => true LS bit (should have been set
					; in main-line code)
	nop
	stm	#2,AR3            ; Set state to 2, wait for end of sequence
	b	major_x
;
; State 2: Check for end-of-sequence (AR2 = depth)
;
end_of_seq:
	cmpm	AR2,#depth		; See if all of sequence has been sent (AR2 holds word count)
	bc	major_x,NTC		; Stay in state 2 until end-of-sequence
	stm	#3,AR3		; Set state to 3, allow TLM FIFO to empty
	b	major_x
;
; State 3: Major frame to allow TLM FIFO to empty
;
tlm_empty:
	stm	#0,AR3		; Set state back to zero, start new sequence
					; on next Major Frame					
major_x:
;
; Major frame counter (32 bits, using AR4 and AR5)
;
	mar	*AR4+
	cmpm	AR4,#0		; Has count rolled over?
	bc	skip_major_ms, NTC
	mar	*AR5+		; Increment upper word of major frame count

skip_major_ms:		; 18 Oct. 2006 was branching to "switch"
	popm	AR0		; Retrieve AR0 for use in main
;	rsbx	XF
;
; Word Clock Interrupt
; CHARM does not currently use this
;
word_int:
word_x:
	rete
;
; Test of AD6620 set-up from look-up table
;

table_test:
	ld      #000Dh,A	; Output CR 
	call	asx
	ld      #000Ah,A	; LF 
	call	asx

	ld	#ad6620_filter,A
	call	rsp_setup
	b	appent

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
	ld	#ad6620_msg1,A	; Tell operator what is happening
;	call	msgout	

rsp_loop:
	ldm	AR2,A		; Retrieve table index
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
	.pstring	"Dartmouth College Master RxDSP  "
;S	.pstring	"Dartmouth College Slave  RxDSP  "
	.word	0000h	; Null terminator
;
; AD6620 set-up messages
;


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
        .word    0300h, 00000h, 00000h, 00900h	; Soft reset, Master
;S      .word    0300h, 00000h, 00000h, 00100h  ; Soft reset, Slave
        .word    0301h, 00000h, 00000h, 00000h	; NCO Control
        .word    0302h, 000FFh, 0FFFFh, 0FF00h	; NCO Sync Mask
;        .word    0303h, 0000Ah, 08F5Ch, 0DA00h	; NCO Frequency = 2.75 MHz
; 23 Dec 2009
        .word    0303h, 0000Ah, 040B8h, 02C00h  ; NCO Frequency = 2.67 MHz
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
        .word    0300H, 00000H, 00000H, 00900H	; Soft Reset, Master
;S      .word    0300H, 00000H, 00000H, 00100H	; Soft Reset, Slave
        .word    0300H, 00000H, 00000H, 00800H	; Run: end of soft reset, Master
;S	  .word    0300h, 00000h, 00000h, 00000h  ; Run: end of soft reset, Slave
        .word    0FFFFH	; End of Table
ad6620_filter_end:

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
        .end
