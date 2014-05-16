;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;============================================================================
; Description:  C54x Double Precision 512-Point Complex FFT
;
; Author:       Aaron Aboagye, Texas Instruments, Inc., Oct 14, 1998
;		from inverse code by Mike Hannah,  Texas Instruments, Inc.,  May 14, 1998
;
; Function:     _cfft32_512
;
; Inputs:       pInBuff in acc A
;
; Assumptions:  Input data is in InBuff and output will be in InBuff.
;               SXM=1 and FRCT=1.  CPL=1 since called from C.
;
;=============================================================================

N	.set	512

	.global	fftStage1and2
	.global fftStage3
	.global fftStageX
	.global fftButterfly
	.global	Tempdw1
	.global	Tempdw2
	
	.include sin_q31.tab

        .mmregs

;	.text
        .sect ".cfft_p"

        .global _cfft32_512

_cfft32_512:
        PSHM    ST0                                 ; 1 cycle
        PSHM    ST1                                 ; 1 cycle

        pshm    ar1
        pshm    ar6
        pshm    ar7

        ssbx	CPL
        RSBX    OVA                                 ; 1 cycle
        RSBX    OVB                                 ; 1 cycle

        rsbx    ovm                     ;disable overflow mode
        ssbx    sxm                     ;sxm enabled
        ssbx    frct                    ;<<1 to make Q31 from Q30 product
        stm     #0, BK                  ;use circ addressing in butterfly with zero length
        stlm    A, ar1                  ;store pInBuff into ar1
        pshm    ar1                     ;put pInBuff on stack for reuse

        ld      #-2, ASM                ;>>2 on stores to mem
;===== Compute 1st and 2nd stages of FFT =====
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;pointer to DATA       r1,i1
        add     #(2*2),A
        stlm    A,ar3                   ;pointer to DATA + 2   r2,i2
        ld      *SP(0),A                ;pointer to DATA -> A
        add     #(4*2),A
        stlm    A,ar4                   ;pointer to DATA + 4   r3,i3
        stm     #7*2-1,ar0              ;index
        stm     #512/4-1,BRC            ;execute N/4-1 times
        ld      *SP(0),A                ;pointer to DATA -> A
        add     #(6*2),A
        stlm    A,ar5                   ;pointer to DATA + 6   r4,i4

	.if	__far_mode
        fcall    fftStage1and2          ;in-place
	.else
        call     fftStage1and2
	.endif

;===== Compute 3rd stage of FFT =====
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;pointer to DATA       pr,pi
        add     #(8*2),A
        stlm    A,ar3                   ;pointer to DATA + 8   qr,qi
        stm     #9*2-1,ar0              ;index
        stm     #512/8-1,BRC            ;execute N/8-1 times '4 macros'
        stm     #Tempdw1,ar5            ;temp dword
        stm     #Tempdw2,ar6            ;temp dword
        stm     #SIN45+1,ar4            ;32-bit sin45 twiddle LSW

	.if	__far_mode
        fcall    fftStage3               ;in-place
	.else
        call     fftStage3
	.endif

;===== Compute 4th stage of FFT =====
;stdmacro .macro  DATA,stage,l1,l2,idx,sin,cos
;        stdmacro dstn,4,32,8,16,isin4,cos4
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;ar2 -> DATA
        add     #(16*2),A
        stlm    A,ar3                   ;ar3 -> DATA+(offset=idx)
        stm     #16*2,ar0               ;index
        stm     #32-1,ar1               ;outer loop counter
        stm     #cos4+1,ar6             ;start on LSW of cosine in stage
        stm     #isin4+1,ar7            ;start on LSW of sine in stage
        stm     #3,AR4                  ;store index offset for butterfly optimization
        pshm    AR4
        stm     #8-2,AR4                ;execute startup + num-2 times general butterfly
        pshm    AR4                     ;save for reuse in butterfly

	.if	__far_mode
        fcall    fftStageX               ;in-place
	.else
        call     fftStageX
	.endif

        frame   #2
        nop
 ;===== Compute 5th stage of FFT =====
;stdmacro .macro  DATA,stage,l1,l2,idx,sin,cos
;       stdmacro dstn,5,16,16,32,isin5,cos5
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;ar2 -> DATA
        add     #(32*2),A
        stlm    A,ar3                   ;ar3 -> DATA+(offset=idx)
        stm     #32*2,ar0               ;index
        stm     #16-1,ar1               ;outer loop counter
        stm     #cos5+1,ar6             ;start on LSW of cosine in stage
        stm     #isin5+1,ar7            ;start on LSW of sine in stage
        stm     #3,AR4                  ;store index offset for butterfly optimization
        pshm    AR4
        stm     #16-2,AR4               ;execute startup + num-2 times general butterfly
        pshm    AR4                     ;save for reuse in butterfly

	.if	__far_mode
        fcall    fftStageX               ;in-place
	.else
        call     fftStageX
	.endif

        frame   #2
        nop
;===== Compute 6th stage of FFT =====
;stdmacro .macro  DATA,stage,l1,l2,idx,sin,cos
;        stdmacro dstn,6,8,32,64,isin6,cos6
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;ar2 -> DATA
        add     #(64*2),A
        stlm    A,ar3                   ;ar3 -> DATA+(offset=idx)
        stm     #64*2,ar0               ;index
        stm     #8-1,ar1                ;outer loop counter
        stm     #cos6+1,ar6             ;start on LSW of cosine in stage
        stm     #isin6+1,ar7            ;start on LSW of sine in stage
        stm     #3,AR4                  ;store index offset for butterfly optimization
        pshm    AR4
        stm     #32-2,AR4               ;execute startup + num-2 times general butterfly
        pshm    AR4                     ;save for reuse in butterfly

	.if	__far_mode
        fcall    fftStageX               ;in-place
	.else
        call     fftStageX
	.endif

        frame   #2
        nop
;===== Compute 7th stage of FFT =====
;stdmacro .macro  DATA,stage,l1,l2,idx,sin,cos
;        stdmacro dstn,7,4,64,128,isin7,cos7
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;ar2 -> DATA
        add     #(128*2),A
        stlm    A,ar3                   ;ar3 -> DATA+(offset=idx)
        stm     #128*2,ar0              ;index
        stm     #4-1,ar1                ;outer loop counter
        stm     #cos7+1,ar6             ;start on LSW of cosine in stage
        stm     #isin7+1,ar7            ;start on LSW of sine in stage
        stm     #3,AR4                  ;store index offset for butterfly optimization
        pshm    AR4
        stm     #64-2,AR4               ;execute startup + num-2 times general butterfly
        pshm    AR4                     ;save for reuse in butterfly

	.if	__far_mode
        fcall    fftStageX               ;in-place
	.else
        call     fftStageX
	.endif

        frame   #2
        nop
;===== Compute 8th stage of FFT =====
;stdmacro .macro  DATA,stage,l1,l2,idx,sin,cos
;        stdmacro dstn,8,2,128,256,isin8,cos8
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;ar2 -> DATA
        add     #(256*2),A
        stlm    A,ar3                   ;ar3 -> DATA+(offset=idx)
        stm     #256*2,ar0              ;index
        stm     #2-1,ar1                ;outer loop counter
        stm     #cos8+1,ar6             ;start on LSW of cosine in stage
        stm     #isin8+1,ar7            ;start on LSW of sine in stage
        stm     #3,AR4                  ;store index offset for butterfly optimization
        pshm    AR4
        stm     #128-2,AR4              ;execute startup + num-2 times general butterfly
        pshm    AR4                     ;save for reuse in butterfly

	.if	__far_mode
        fcall    fftStageX               ;in-place
	.else
        call     fftStageX
	.endif

        frame   #2
        nop
;===== Compute 9th (last) stage of FFT =====
;laststag .macro  DATA,stage,sin,cos
;        laststag dstn,9,isin9,cos9
        ld      *SP(0),A                ;pointer to DATA -> A
        stlm    A,ar2                   ;ar2 -> DATA
        add     #(512*2),A
        stlm    A,ar3                   ;ar3 -> DATA+(offset=N)
        stm     #512/2-2,BRC            ;execute startup + num-2 times general butterfly
        stm     #cos9+1,ar4             ;start on LSW of cosine in stage
        stm     #isin9+1,ar5            ;start on LSW of sine in stage

	.if	__far_mode
        fcalld   fftButterfly           ;execute N/2 butterflies in-place
	.else
        calld    fftButterfly
	.endif

        stm     #3,AR0                  ;store index offset for butterfly optimization

        popm    ar1                     ;remove pInBuff from stack
        popm    ar7
        popm    ar6
        popm    ar1
        POPM    ST1                                 ; 1 cycle
        POPM    ST0                                 ; 1 cycle

	.if	__far_mode
        fret
        .else
        ret
        .endif
