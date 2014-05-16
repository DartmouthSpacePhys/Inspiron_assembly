****
* Prescaling function for TI DSP Library Logarithm by Micah P. Dombrowski
* 
* Normalizes each 32-bit value using EXP and NORM, 
* saving the shift values for later adjustment post-logarithm,
* and cutting to 16-bit output
****

* Inputs: N, number of values to scale in Acc,
* 	on Stack: 	data input address (512x2 words present),
*				data output address (512 words free),
*				scale save address (512 words free)

* History
* 
* v1.0 	12 June 2012	Created
*

	.mmregs

; Stack usage
		; 0 = ST1, 1 = ST0, 2 = function return pointer
	.asg    *SP(3), idata
	.asg	*SP(4), odata
	.asg	*SP(5), sdata

	.def	_sqmag_prescale
	.sect	.sqpre_p
_sqmag_prescale

; Set up processor for fractional, signed math
	pshm	ST0
	pshm	ST1
	ssbx	CPL
	rsbx	FRCT
	ssbx	SXM
	ssbx	OVM
	rsbx	C16
	nop
	nop
	
	sub	#1, A	; BRC = N-1
	stlm	A, BRC
	stm		#16, AR0	; max shift value
	mvdk	idata, AR2	; input pointer
	mvdk	odata, AR3	; output pointer
	mvdk	sdata, AR4	; scale array pointer
	
	rptb	log_prescale_loop - 1
	
	dld		*AR2+, A
	dld		*AR2+, B
	
	exp		A
	mvdm	@T, AR0
	exp		B
	mvdm	@T, AR1
	
	cmpr	GT, AR1	; if AR1 <= AR0, the right value is already in T
	nop
	nop
	xc		2, TC
	mvmd	AR0, T	; if AR1 > AR0, we need to copy AR0 back into T
	nop
	
	pshm	T	; save T to stack
		
	norm	A	; shift
	norm	B
	
	dst		A, *AR3+	; save data
	dst		B, *AR3+

	cmpm	*SP(0), #0	; this references the saved T value on top of stack
	nop
	nop
	xc		2, TC
	st		#31, *SP(0)	; if 0, assume it was EXP(0), set scaling to max
	
	ld		#0, A 	; clear Acc
	popm	AL		; pop the corrected scale factor into low Acc
	
	stl		A, 1, *AR4+		; save with a 1-bit shift (mpy by 2)

log_prescale_loop:

	popm	ST1
	popm	ST0
	
	retd
	nop
	nop

	.end