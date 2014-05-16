****
* Double-precision square magnitude function by Micah P. Dombrowski
* 
* Reads n Q.31 numbers arrayed as R[0], I[0], R[1], I[1], ..., R[n-1], I[n-1]
* outputs MSB half of R[0]^2+I[0]^2, R[1]^2+I[1]^2, ..., R[n-1]^2+I[n-1]^2
* output fills first half of input region
****

* Inputs: data address in A, number of R/I pairs in B

* History
* 
* v1.0 	12 June 2012	Extracted to separate asm file, set up as a CALLable function.
*

	.mmregs
	.def	_sqmag
	.sect	.spsm_p
_sqmag

	pshm	ST1
	ssbx	SXM
	ssbx	FRCT
	ssbx	OVM
	rsbx	C16
	nop
	nop
	
; Double-precision square magnitude, saving MSB half of result.

	stm		#0, T	; Multiplication Temp register (for mpy)
	stm		#0, BK	; Circuluar addressing modulus (do not want)
	sub		#1, B
	stlm	B, BRC
	stm		#2, AR0		; Increment (jump to next 32-bit datum)
	stlm	A, AR2		; Load index
	stlm	A, AR4		; Storage index
	rptb	sqmag_loop - 1
	
	dld		*AR2+, A
	sfta	A, #8
	sfta	A, #8
	squr	A, B
    sat 	B
    	
	dld		*AR2+, A
	sfta	A, #8
	sfta	A, #8
	squr	A, A
    sat 	A
    
    add		B, A		; a += b == R^2 + I^2
    sat		A
	stl		A, *AR4+	; (1)
	
sqmag_loop:

	popm	ST1
	
	retd
	nop
	nop
