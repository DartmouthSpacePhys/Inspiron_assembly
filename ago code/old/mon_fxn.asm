;
; TMS320C542 Debug Monitor - Translated (and modified) from 'C50 version
;
; Vandiver Electronics
; 741 Chase Road 
; Huntsville, Alabama 35811
;



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
eeprom_burn_start:	
	ld      #eb_wff,A	; Start-up message	
	call	msgout

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

	ld      #eb_end,A	; Start-up message	
	call	msgout
	
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

eb_wff:
	.word	0D0Ah
	.pstring "Waiting for data... "
	.word	0D0Ah, 0000h

eb_end:
	.word	0D0Ah
	.pstring "...done."
	.word	0D0Ah, 0000h

version:
	.word	0D0Ah
	.pstring "Vandiver Electronics TMS320C542 Monitor "
	.word	0D0Ah
	.pstring "Version 2.04, Dartmouth South-Pole Rx-DSP"
	.word	0D0Ah
	.pstring "Dual-code, 20 October 2011"
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
	.word	0D0Ah
	.pstring "X                   eXecute DSP appcode (eXit monitor)"
	.word	0D0Ah,0000h

