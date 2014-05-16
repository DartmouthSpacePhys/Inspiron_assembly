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
	.sect	.dpsm_p
_sqmag

	pshm	ST0
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
	stlm	A, AR3		; Load index
	stlm	A, AR4		; Storage index
	rptb	sqmag_loop - 1
	
	mpy		*AR2+, A			; a = 0 			(1)
	macsu	*AR2-, *AR3+, A 	; a  = RL*RH		(1)
	macsu	*AR3-, *AR2, A		; a += RH*RL		(1)
	ld		A, -16, A 			; a >>= 16			(1)
	mac		*AR2+0%, *AR3+0%, A	; a += RH*RH		(1)
	stm		#0, T		; (2)
    sat 	A           ; (1)
	
	mpy		*AR2+, B			; b = 0 			(1)
	macsu	*AR2-, *AR3+, B 	; b  = IL*IH		(1)
	macsu	*AR3-, *AR2, B		; b += IH*IL		(1)
	ld		B, -16, B 			; b >>= 16			(1)
	mac		*AR2+0%, *AR3+0%, B	; b += IH*IH		(1)
	stm		#0, T		; (2)
    sat 	B           ; (1)

    
    add		B, A		; a += b == R^2 + I^2
    sat		A
	dst		A, *AR4+	; (1)
	
sqmag_loop:

	popm	ST1
	popm	ST0

	nop
	nop
		
	retd
	nop
	nop
