data_process:


	.global pre_window
pre_window:

	ld	#iq_data, A
	ld	#data_n, B
	
	call	_hann_window

	.global	pre_bit_rev
pre_bit_rev:
	
; Bit reversal
	stm		#data_n, AR0
	pshm	AR0
	stm		#iq_data, AR0
	pshm	AR0
	ld		#iq_data, A
	
	call _cbrev32
	
	frame	2


	.global pre_fft
pre_fft:
	stm		#fft_scaling, AR0
	pshm	AR0
	ld		#fft_data, A
	
	call 	_cfft32_512
	
	frame	1

	
	.global	pre_move
pre_move:
; flip things into proper power spectra order (swap halves)
; remove zeroes here, too

	stm		#(data_n-1), BRC
	stm		#fft_data, AR2
	stm		#(fft_data + 2*data_n), AR3
	
	rptb	move_loop - 1

	dld		*AR2, A
	dld		*AR3, B
	
	nop
	nop
	xc		2, AEQ
	add		#1, A
	xc		2, BEQ
	add		#1, B
	
	dst		A, *AR3+
	dst		B, *AR2+	
	
move_loop:
	

	.global	pre_sqscale
pre_sqscale:

	stm		#scale_addr, AR0	; scale saves
	pshm	AR0
	stm		#fft_data, AR0		; output
	pshm	AR0
	stm		#fft_data, AR0		; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_sqmag_prescale
	
	frame	3	; free stack


	.global pre_abs
pre_abs:
	ssbx	SXM
	ssbx	OVM
	nop
	nop

	stm		#(2*data_n-1), BRC
	stm		#fft_data, AR0
	rptb	abs_loop - 1
	
	dld		*AR0, A
	abs		A
	dst		A, *AR0+

abs_loop:


	.global	pre_sqmag, pre_log, pre_db
pre_sqmag:
; |FFT|^2
	ld		#sqmag_data, A
	ld		#data_n, B
	
	call	_sqmag




	.global pre_logps
pre_logps:
	
	stm		#scale_data, AR0	; scale saves
	pshm	AR0
	stm		#sqsc_data, AR0	; output
	pshm	AR0
	stm		#sqmag_data, AR0				; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_log_prescale
	
	frame	3


pre_scale:
	

pre_log:
; log_10(|FFT|^2) (outputs 32-bit Q16.15)

	stm		#data_n, AR0
	pshm	AR0
	stm		#log_data, AR0			; write to beginning of data buffer
	pshm	AR0
	ld		#sqsc_data, A	; read from halfway point of data buffer
	
	call _log_10

	frame	2


	.global pre_descale
pre_descale:

	stm		#scale_data, AR0	; scale saves
	pshm	AR0
	stm		#power_data, AR0		; output
	pshm	AR0
	stm		#log_data, AR0		; input
	pshm	AR0
	ld		#data_n, A	; N

	call	_descale
	
	frame	3	; free stack


	.global post_descale
post_descale:
; multiply by output_scale_factor, shift right by output_shift_n, re-store

	pshm	ST0
	pshm	ST1
	ssbx	FRCT
	ssbx	SXM
	ssbx	OVM
	rsbx	C16

; Scale and shift, save 8-bit data

	stm		#data_n-1, BRC
	stm		#power_data, AR0
	stm		#(data_addr + 2*data_n), AR1
	stm		#ebs_data, AR2
;	stm		#output_scale_factor, T
	rptb	ebs_loop - 1
	
;	mpy		*AR0+, A	; multiply by scale factor in T
;	sfta	A, #0-output_shift_n
;	and		#0xFF0000, A
;	dst		A, *AR1+
	
;	mpy		*AR0+, A	; multiply by scale factor in T
	ld		*AR0+, A
	sfta	A, #0-output_shift_n
	add		#128, A
	and		#0xFF, A
	stl		A, *AR2+
;	dadd	output_shift_n, A	; shift
;	sat		A
;	and		#0xFF, #16, A			; mask to A(23-16)
;	sth		A, *AR2+				; store A(23-16)
	
ebs_loop:

	nop

	.global	dp_end
dp_end:

	popm	ST1
	popm	ST0

	nop