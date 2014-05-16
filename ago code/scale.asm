* * * *
* Prescaling functions by Micah P. Dombrowski
* 
* _sqmag_prescale
*
*	Used on 32-bit complex number array (stored RIRIRI), finds the largest possible shift 
* 	applicable to each RI pair using EXP.  Assumes a zero return equates to EXP(0), and 
* 	stores the maximum shift.  Stores 2*shift in scale factor array.
*
* _log_prescale
*
*	For TI DSP Library Logarithm: normalizes each 32-bit value using EXP and NORM, adding 
*	shift values to existing values in the save array, and cutting to 16-bit output
*
* _descale
* 
* 	Adjusts logarithmic output based on scale factor array, by subtracting scale*log10(2).
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

***
* _sqmag_prescale
*
* Inputs: 	N, number of values to scale in Acc,
* 	ToS:	 	data input address (512x2 words present), 
*				data output address (512 words free),
*				scale save address (512 words free)

* History
* 
* v1.0 	13 June 2012	Created.
* v1.1	14 June 2012	Discovered a CMP? then XC chain needs two NOPs in between.  Wat.
*						Moved to single scale code file.

_sqmag_prescale

; Set up processor for signed, non-fractional math
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
	
	rptb	sqmag_prescale_loop - 1
	
	dld		*AR2+, A
	dld		*AR2-, B
	nop
	nop

	exp		A
	nop
	ldm		T, A
	
	exp		B
	nop
	ldm		T, B
	
	min		A		; A = min(A,B)
	nop
	nop

	sub		#4, A	; 4 guard bits
	
	
	stlm	A, T	; re-store to T
	nop
	nop
	
	pshm	T	; save T to stack

	dld		*AR2+, A
	dld		*AR2+, B
	nop
	nop
		
	norm	A	; shift
	norm	B
	
	.global norm_ovm
norm_ovm:
	
	dst		A, *AR3+	; save data
	dst		B, *AR3+

	ld		#0, A 	; clear Acc
	popm	AL		; pop the corrected scale factor into low Acc
	stl		A, 1, *AR4+		; save with a 1-bit shift (mpy by 2)

sqmag_prescale_loop:

	popm	ST1
	popm	ST0
	
	retd
	nop
	nop


***
* _log_prescale
*
* Inputs: 	N, number of values to scale in Acc,
* 	ToS:	 	data input address (512x2 words present),
*				data output address (512 words free),
*				scale save address (512 words free)

* History
* 
* v1.0 	12 June 2012	Created
* v1.1	14 June 2012	Moved to single scale code file.

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
	nop
	
	ldm		T, B		; load T
	sub		#4, B		; guard bits
	stlm	B, T
	add		*AR4, B		; add any existing scale factor
	stl		B, *AR4+	; save back to scale array
	nop
	nop
			
	norm	A	; shift
	
	sth		A, *AR3+	; save data

log_prescale_loop:

	popm	ST1
	popm	ST0
	
	retd
	nop
	nop


***
* _descale
*
* Inputs:	N, number of input points, in Acc
*	ToS:		data input address (512x2 words present, Q16.15 format)
*				data output address	(512 words free, in-place okay)
*				scale factor array (512 words present)

* History
*
* v1.0	14 June 2012	Created.
*

log10o32767	.set	0x783F	; ( log10(32767) * 2^15) >> 3
log10o2		.set	0x04D1	; ( log10(2) * 2^15 ) >> 3


_descale:

	pshm	ST0
	pshm	ST1
	ssbx	CPL
	rsbx	FRCT
	ssbx	SXM
	rsbx	OVM
	rsbx	C16
	nop
	nop
	
	sub	#1, A	; BRC = N-1
	stlm	A, BRC
	mvdk	idata, AR2	; input pointer
	mvdk	odata, AR3	; output pointer
	mvdk	sdata, AR4	; scale array pointer

	rptb	descale_loop - 1
	
	; Docs say log10 outputs Q16.15, but this is misleading,
	; format is S IIII IIII IIII IIII FFFF FFFF FFFF FFF
	dld		*AR2+, A
	sfta	A, #-3
	
	ld		#log10o32767, B
	add		B, A
	
	ld		#log10o2, B

	rpt		*AR4+
	sub		B, A
	sfta	A, #8
	sfta	A, #8
	sat		A
	
	sth		A, *AR3+
	
descale_loop:

	popm	ST1
	popm	ST0

	retd
	nop
	nop
	
	
	.end