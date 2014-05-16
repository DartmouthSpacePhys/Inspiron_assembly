* * * *
* Header writing function by Micah Dombrowski
* 
* _hwrite
*
* Feed it addresses for output, unit # address, center frequency, and major frame counter.
* Writes a 32-bit header
*
* * * *

	.mmregs

; Stack usage
		; 0 = ST1, 1 = ST0, 2 = function return pointer
	.asg    *SP(3), idata
	.asg	*SP(4), odata
	.asg	*SP(5), sdata
	
	.def	_sqmag_prescale, _log_prescale, _descale
	.sect	.scale_p

hwrite:
; Write out header

	st		#0xFE, *AR4+
	st		#0x6B, *AR4+
	st		#0x28, *AR4+
	st		#0x40, *AR4+
	
	static_header_p1:
	.word	0xFE, 0x6B, 0x28, 0x40
	.string	"RxDSP"
	.word		0000h	; Null terminator

	stm		#static_header, AR0	; Point to static header words
header_loop:
	ld		*AR0+, A		; Get a word, point to next
	bc		header_loop_x, AEQ		; If terminator, end static header
	stl		A, *AR4+		; Write to serial buffer
	b		header_loop
header_loop_x:

	ld		@unit_designation, A	; load unit number
	add		#0x30, A				; add 0x30 (ASCII "0")
	stl		A, *AR4+				; store
	st		#0x2E, *AR4+			; tack on a fullstop.  FANCY.
