****
* Frequency selection and averaging function by Nathan Utterback and Micah P. Dombrowski
* 
* Normalizes each 32-bit value using EXP and NORM, 
* saving the shift values for later adjustment post-logarithm,
* and cutting to 16-bit output
****

* Inputs: start address of data Acc,
* 		  output address in Bcc

* History
* 
* v1.0  9 Aug 2012	Averaging implemented
* v1.0 	8 Aug 2012	Copied from tabletransfer.asm
*

avg_shift_val	.set	3	; bits to right shift by after summing

	.mmregs
	.def 	transfer, transfer_table_sz
	.sect 	.transfer_p

	.bss 	Delta,1,0,0  ; storage for repeat counter
	.bss 	nShift,1,0,0 ; storage for shift value

transfer:

	pshm	ST0
	pshm	ST1

	pshm	AR6
	
	stlm	A, AR2
	stlm	B, AR3
	stm		transfer_table_start, AR5	; load the start of the table into memory
	stm		transfer_table_end-1, AR0

	
transfer_sum_loop:

	ldm		AR2, A		; load base address
	add		*AR5+, A	; add offset from table, inc
	stlm	A, AR4		; store
	
	ld		*AR5-, A	; load next offset, dec
	sub		*AR5+, A	; subtract current offset to get delta, inc
	sub		#1, A
	stlm	A, BRC	; store delta-1 for rpt
	
	ld		#0, B
	rptb	max_loop - 1
	
	ld		*AR4+, A
	max		B
	
max_loop:
		
	stl		B, *AR3+ 	; save
	
	cmpr	LT, AR5
	bc		transfer_sum_loop, TC	; loop until we finish the table


	popm	AR6

	popm	ST1
	popm	ST0
			
	retd
	nop
	nop
	
transfer_table_start:
	.word	25, 33, 41, 49, 57, 65, 73, 81, 89, 97, 105

	.word 	113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130 
	.word 	131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148
	.word 	149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165

	.word 	166, 174, 182, 190, 198, 206, 214, 222, 230, 238, 246, 254, 262, 270, 278, 286, 294, 302 
	.word 	310, 318, 326, 334, 342, 350, 358, 366, 374, 382, 390, 398, 406, 414, 422, 430, 438, 446
	.word 	454, 462, 470, 478
transfer_table_end:

transfer_table_sz	.set	transfer_table_end-transfer_table_start