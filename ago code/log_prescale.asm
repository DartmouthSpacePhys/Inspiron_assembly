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

	.def	_log_prescale
	.sect	.logpre_p
_log_prescale

; Set up processor for fractional, signed math
	pshm	ST0
	pshm	ST1
	ssbx	CPL
	ssbx	FRCT
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
	exp		A
	
	ldm		T, B		; load T
	add		*AR4, B		; add any existing scale factor
	stl		B, *AR4+	; save back to scale array
			
	norm	A	; shift
	
	sth		A, *AR3+	; save data

log_prescale_loop:

	popm	ST1
	popm	ST0
	
	retd
	nop
	nop

	.end