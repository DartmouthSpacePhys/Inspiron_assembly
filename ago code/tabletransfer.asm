
	.mmregs
	.def transfer, transfer_table_sz
	.sect .transfer_p

transfer:

	pshm	ST0
	pshm	ST1
	pshm	AR6

	stlm	A, AR2
	stlm	B, AR3
	stm		#transfer_table_sz - 1, BRC
	stm		transfer_table_start, AR6	;load the start of the table into memory
	
	rptb	transfer_loop - 1
	
	ld		AR2, A	;load the data address into AR7
	add		*AR6+, A		;increment AR7 to the next relevant fft point
	reada 	*AR3+			;or whatever the current serial transfer is

transfer_loop:

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