	.mmregs
	.def transfer, transfer_table_sz
	.sect .transfer_p

transfer:
	stm		#transfer_bittab_sz, BRC
	stm		#15, AR0
	stlm	A, AR2
	stlm	B, AR3
	stm	transfer_bittab_start, AR4	;load the start of the table into memory
	
	
	rptb	transfer_end - 1
	
	stm		#0, AR1

transfer_word_parse:

	ld		AR1, T
	bitt	*AR4
	nop
	nop
	xc		1, TC
	mvdd	*AR2, *AR3+	; copy data if true
	
	mar		*AR2+	; inc source regardless

	cmpm	LT, AR1	
	bcd		transfer_word_parse, TC
	mar		*AR1+
	nop
	
transfer_end:

	retd
	nop
	nop

iteration:



	ld		AR2, A	;load the data address into AR7
	add		*AR6+, A		;increment AR7 to the next relevant fft point
	reada 	*AR3+			;or whatever the current serial transfer is
	cmpm	*AR6, #transfer_table_end
	bc	iteration, NTC		;loop to iteration
	
	ldm		AR3, B	; return new data address in B

	retd
	nop
	nop

transfer_bittab_start:
	; columns of 4x16-bit words = 64 bits per row, 16 rows of 64 columns = 1024 total bits
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;    0 to   63
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;   64 to  127
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;  128 to  191
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;  192 to  255
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;  256 to  319
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;  320 to  383
	.word	1000000000000000b, 1000000000000000b, 1000000000000000b, 1000000000000000b	;  384 to  447
	.word	1000000000000000b, 1000000000000000b, 1000000000000111b, 1111111111111111b	;  448 to  511
	.word	1111111111111111b, 1110000000000001b, 0000000000000001b, 0000000000000001b	;  512 to  575
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  576 to  639
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  640 to  703
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  704 to  767
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  768 to  831
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  832 to  895
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  896 to  959
	.word	0000000000000001b, 0000000000000001b, 0000000000000001b, 0000000000000001b	;  960 to 1023
transfer_bittab_end:

transfer_bittab_start:
	; columns of 3x16-bit words = 48 bits per row, 20 rows of 48 columns + 1 row of 64 = 1024 total bits
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	   0 to   47
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	  48 to   95
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	  96 to  143
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 144 to  191
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 192 to  239
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 240 to  287
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 288 to  335
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 336 to  383
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 384 to  431
	.word	1000000000001000b, 0000000010000000b, 0000100000000000b		;	 432 to  479
	
	.word	1000000000001000b, 0000000111111111b, 1111111110000000b, 0001000000000001b	; 480 to 543
	
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	   0 to   47
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	  48 to   95
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	  96 to  143
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 144 to  191
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 192 to  239
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 240 to  287
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 288 to  335
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 336 to  383
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 384 to  431
	.word	0000000000010000b, 0000000100000000b, 0001000000000001b		;	 432 to  479
transfer_bittab_end:
