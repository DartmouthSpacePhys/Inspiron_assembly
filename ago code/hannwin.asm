****
* Hann window function by Micah P. Dombrowski
* 
* Applies a Hann window, in-place, to Q.15 I/Q complex numbers
****

* Inputs: data address in A, number of I/Q pairs in B

* History
* 
* v1.0 	1 June 2012	Extracted to separate asm file, set up as a CALLable function.
*

	.mmregs
	.def	_hann_window
	.ref	_hann_table
	.sect	.hann_p
_hann_window

; Set up processor for fractional, signed math
	pshm	ST0
	pshm	ST1
	ssbx	FRCT
	ssbx	SXM
	ssbx	OVM
	rsbx	C16
	nop
	nop
	
	sub	#1, B	; BRC = N-1
	stlm	B, BRC
	stm	#2, AR0
	stlm	A, AR2
	stm	_hann_table, AR3
	nop
	nop
	rptb	window_loop - 1
	
	ld	#0, A 			; Acc <- 0
	macr	*AR2, *AR3, A		; Acc <- round(I_n * win_n) (clears Acc[15:0])
	sfta	A, -16			; Acc <- Acc >> 16 (arithmetic shift)
	dst	A, *AR2+		; double store Acc (increments by 2)
	
	ld	#0, A			; Acc <- 0
	macr	*AR2, *AR3, A		; Acc <- round(Q_n * win_n) (increment win_n)
	sfta	A, -16
	dst	A, *AR2+
	
	mar	*AR3+0
window_loop:

	popm	ST1
	popm	ST0
	
	retd
	nop
	nop

	.end