****
* Serial data cooking function by Micah P. Dombrowski
* 
* Reads N words containing right-aligned bytes, 
* bit reverses, and adds start and stop bits.
****

* Inputs: data address in A, number of bytes in B

* History
* 
* v1.0 	3 June 2012	Extracted to separate asm file, set up as a CALLable function.
*

	.mmregs
	.def	_serial_cook
	.sect	.sercook_p
_serial_cook

	sub	#1, B
	stlm	B, BRC
	stlm	A, AR0
	rptb	bitrev_loop - 1

	ssbx	XF

	ld		#1, B			; zero result + stop bit
	
	ld		#001h, A	; load mask
	and		*AR0, A		; mask data
	or		A, 8, B		; OR into result
	ld		#002h, A
	and		*AR0, A
	or		A, 6, B
	ld		#004h, A
	and		*AR0, A
	or		A, 4, B
	ld		#008h, A
	and		*AR0, A
	or		A, 2, B
	ld		#010h, A
	and		*AR0, A
	or		A, 0, B
	ld		#020h, A
	and		*AR0, A
	or		A, -2, B
	ld		#040h, A
	and		*AR0, A
	or		A, -4, B
	ld		#080h, A
	and		*AR0, A
	or		A, -6, B

	stl		B, *AR0+			; rewrite to serial buffer
	
	rsbx	XF	
	
bitrev_loop:

	retd
	nop
	nop
	
	.end
