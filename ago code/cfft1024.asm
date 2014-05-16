;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;*****************************************************************************
;  Function:	 cfft1024
;  Description:  complex FFT
;
;  Copyright Texas instruments Inc, 1998
;-----------------------------------------------------------------------------
; Revision History:
;
; 0.00	M. Christ. Original code
; 0.01	M. Chishtie.12/96.
;	- Improved radix-2 bfly code form 9 cycles to 8.
;	- Combined bit-reversal in to COMBO5XX macro to save cycles.
;	- Improved STAGE3 macro to 31 cycles
; 1.00Beta  R. Piedra, 8/31/98.
;	- C-callable version.
;	- Removed bit-reversing and made it a separate optional function
;	  that also support in-place bit-reversing. In this way the FFT can
;	  be computed 100% in-place (memory savings)
;	- Modifed STAGE3 macro to correct functional problem
;	- Modified order of xmem, ymem operands in butterfly code
;	  to reduce number of cycles
;
; 1.00	 A. Aboagye 10/15/98
;	 - added scale option as a parameter
;
;*****************************************************************************

    .mmregs
	.ref	sin4,sin5,sin6,sin7,sin8,sin9,sina
	.ref	cos4,cos5,cos6,cos7,cos8,cos9,cosa
    
FFT_N	 .set	    1024  ; NUMBER OF POINTS FOR FFT

	.include "macros.asm"

; Far-mode adjustment
; -------------------


	; stack address in A
	.asg	(0), DATA
	.asg	(1), SIN45
		; pos 2 & 3 are ST1 & ST0 state saves
	.asg	(4), save_ar7		; stack description
	.asg	(5), save_ar6		; stack description
	.asg	(6), save_ar1
	.asg	(7), ret_addr
	.asg	(8), scale
					; x in A

;*****************************************************************************
	 .def	_cfft1024
;	 .text
	.sect	.cfft_p
	
_cfft1024

; Preserve registers
; ------------------
	pshm	ar1
	pshm	ar6
	pshm	ar7

        PSHM    ST0                                 ; 1 cycle
        PSHM    ST1                                 ; 1 cycle
        RSBX    OVA                                 ; 1 cycle
        RSBX    OVB                                 ; 1 cycle

; Set modes
; ---------
	orm   #0100110101011110b,*(ST1)
; 	BRAF	CPL		XF	HM	INTM	0	OVM		SXM		C16		FRCT	CMPT	ASM
;	0		1		0	0	1		1	0		1		0		1		0		11110

	ssbx	CPL
	ssbx	OVM

; Preserve local variables
; ------------------------
	frame	-2
	nop
	nop

; Get Arguments
; -------------

	stl		a, *sp(DATA)	; DATA = *SP(DATA)

	.if   	FFT_N>4			; ??? no need
	st    	#5a82h, *sp(SIN45)
	.endif


; Execute
; -------
	.global	fft_stage_1_2,fft_stage_3,fft_stage_4,fft_stage_5,fft_stage_6,fft_stage_7
	.global	fft_stage_8,fft_stage_9,fft_stage_10
fft_stage_1_2:
	combo5xx		     ; FFT CODE for STAGES 1 and 2
fft_stage_3:
    stage3                       ; MACRO WITH CODE FOR STAGE 3
fft_stage_4:
	stdmacro 4,64,8,16,sin4,cos4  ; stage,outloopcnter,loopcnter,index
fft_stage_5:
	stdmacro 5,32,16,32,sin5,cos5 ; stage,outloopcnter,loopcnter,index
fft_stage_6:
	stdmacro 6,16,32,64,sin6,cos6 ; stage,outloopcnter,loopcnter,index
fft_stage_7:
	stdmacro 7,8,64,128,sin7,cos7 ; stage,outloopcnter,loopcnter,index
fft_stage_8:
	stdmacro 8,4,128,256,sin8,cos8 ; stage,outloopcnter,loopcnter,index
fft_stage_9:
	stdmacro 9,2,256,512,sin9,cos9 ; stage,outloopcnter,loopcnter,index
fft_stage_10:
	laststag 10,sina,cosa	      ; MACRO WITH CODE FOR STAGE 10


; Return
;--------

	frame	+2
        POPM    ST1                                 ; 1 cycle
        POPM    ST0                                 ; 1 cycle
	popm	ar7
	popm	ar6
	popm	ar1

	retd
	nop
	nop

;end of file. please do not remove. it is left here to ensure that no lines of code are removed by any editor
