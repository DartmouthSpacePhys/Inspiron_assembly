	nop
	nop
	nop
	nop
	nop
	nop

	stm		#65530, BRC
	nop
	ssbx	XF
	nop
	rptb	qil-1
	
	rpt	#32
	nop
		
qil:

	rsbx	XF	
	
	
	pre_db:
; 50*log_10(|FFT|^2)
	ssbx	SXM
	ssbx	FRCT
		
	stm		#data_n - 1, BRC
	stm		#(data_addr + data_n), AR1
	rptb	db_loop - 1
	
	mpy		*AR1, #10, A
	stl		A, *AR1+
	
db_loop:
	rsbx	SXM	

; transfer selected data to serial buffer
	ld		#data_addr, A
	ld		#data_addr, B
	
	call	transfer
	
	.global	raw_data_transfer
raw_data_transfer:	

	; copy raw data (words) into serial buffer (bytes)
	ld		#data_addr, A
	add		@bridge_count, A
	stlm	A, AR1
	stm		#((abu_buff_sz/2-fsync_sz)/2-1), BRC
	rptb	rawdata_loop - 1
	
	ld		*AR1, -8, A	; load (data word) >> 8 to Acc
	and		#0xFF, A	; mask to low-byte
	stl		A, *AR4+	; save to serial buffer
	
	ld		*AR1+, A 	; reload and increment
	and		#0xFF, A	; mask
	stl		A, *AR4+	; save

	addm	#1, @bridge_count	
	nop
	cmpm	@bridge_count, #bridge_def_sz
	bc		rawdata_bskip, NTC

	rsbx	BRAF
	nop
	nop
	nop
		
rawdata_bskip:

	nop
	nop
	
rawdata_loop:

	nop
	nop


;dw_loop:
;	ld		*AR2+, A
;
;	ld		A, -8, B
;	sftl	B, 1
;	or		#512, B
;	stl		B, *AR1+
;	
;	sftl	A, 1
;	or		#512, A
;	stl		A, *AR1+
;	
;	banz	dw_loop, *AR3-

;	ld		#1FFh, A	; two 0xFF bytes for frame end
;	stl		A, *AR0+
;	stl		A, *AR0+


;pre_dummy:
;	stm		#(data_n/2)-1, BRC
;	stm		#(data_addr + data_n), AR1
;
;	rptb	dummydata_loop - 1
;
;	st		#100, *AR1+
;	
;dummydata_loop:
;
;	stm		#(data_n/2)-1, BRC
;	rptb	dummydata_loop2 - 1
;	
;	st		#1000, *AR1+
;
;dummydata_loop2:
	

;pre_dummy:
;	stm		#(2*data_n/4)-1, BRC
;	stm		#data_addr, AR1
;
;	rptb	dummydata_loop - 1
;
;	st		#6, *AR1+
;	st		#8, *AR1+
;	
;dummydata_loop:
;
;	stm		#(2*data_n/4)-1, BRC
;	rptb	dummydata_loop2 - 1
;	
;	st		#10, *AR1+
;	st		#30, *AR1+
;	
;dummydata_loop2:
	

	

; Load test pattern x 64
;	stm		#data_addr, AR1		; data address
;	stm		#(data_n-1), AR3	; data counter	
;	stm		#1023, BRC
;	rptb	testpatt_loop - 1
;	st		#0x5533, *AR1+
;	st		#0xAA00, *AR1+
	
; Load test ramp x 2048
;	stm		#data_addr, AR1		; data address
;	stm		#8192, AR3				; data counter	
;	stm		#2047, BRC
;	rptb	testpatt_loop - 1
;	mvkd	AR3, *AR1+
;	mar		*AR3+
;
;testpatt_loop:

; Load zeroes x 2048
;	stm		#data_addr, AR1		; data address
;	stm		#2047, BRC
;	rptb	testpatt_loop - 1
;	st		#0, *AR1+
;
;testpatt_loop:

; Write a header "test ramp" to first half buffer
	stm		#abu_buff_loc, AR4		; data address
	stm		#0, AR3				; data counter	
	stm		#abu_buff_sz/8-1, BRC
	rptb	head_ramp - 1
	
;	ldm		AR3, A
;	sftl	A, 1
;	or		#1, A
;	stl		A, *AR4+
	st		#0x1FF, *AR4+
	st		#0x001, *AR4+
	st		#0x1F0, *AR4+
	st		#0x001, *AR4+
;	mar		*AR3+
	
head_ramp:



; find maximum data value

	stm		#data_n-2, BRC
	stm		#data_addr, AR0
	rptbd	max_loop - 1
	ld		*AR0+, A
	nop
	
	ld		*AR0+, B
	max		A
	
max_loop:

	stl		A, @ebs_max
	
; find minimum data value

	stm		#data_n-2, BRC
	stm		#data_addr, AR0
	rptbd	min_loop - 1
	ld		*AR0+, A
	nop
	
	ld		*AR0+, B
	min		A
	
min_loop:
	.global min_loop, max_loop

	stl		A, @ebs_min
	add		@ebs_max, A		; min+max
	sfta	A, #-1 			; div by 2
	
	nop
	nop
	nop
	nop
	nop
	nop
	
; center the power spectrum
;
;	stm		#data_n-1, BRC
;	stm		#data_addr, AR0
;	rptb	center_loop - 1
	
;	ld		*AR0, B
;	sub		A, B
;	stl		B, *AR0+
	
center_loop:
	.global centered
centered:


; old table, skip 6
transfer_table_start:
	.word	  0,   6,  12,  18,  24,  30,  36,  42,  48,  54,  60,  66,  72,  78
	.word	 84,  90,  96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162 
	.word	168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246

	.word	249,250,251,252,253,254
	.word	257,258,259,260,261,262
	
	.word	265, 271, 277, 283, 289, 295, 301, 307, 313, 319, 325, 331, 337, 343 
	.word	349, 355, 361, 367, 373, 379, 385, 391, 397, 403, 409, 415, 421, 427 
	.word	433, 439, 445, 451, 457, 463, 469, 475, 481, 487, 493, 499, 505, 511
transfer_table_end:
