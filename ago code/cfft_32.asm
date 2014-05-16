;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;============================================================================
;  Description:   32-bit Complex FFT
;
;  Target Processor: C54x
;
;  Author:	Aaron Aboagye, Texas Instruments, Inc., Oct 14, 1998
;		from inverse code by Mike Hannah,  Texas Instruments, Inc.,  May 14, 1998
;
;=============================================================================

		.global Tempdw1
		.global Tempdw2
		.global fftStage1and2
		.global fftStage3
		.global fftStageX
		.global fftButterfly

        .mmregs
        .bss Tempdw1,1*2,0,0  ;temporary dword
        .bss Tempdw2,1*2,0,0  ;temporary dword

        .text
;=============================================================================
; Function:     fftStage1and2
;
; Description:  Combined stage 1 and 2 of Complex Inverse FFT (double precision)
;
; Inputs:       None
;
; Outputs:      None
;
; Assumptions:  Output will be in place of input.
;
;=============================================================================
fftStage1and2:
	.if	__far_mode
	ld	*sp(10), A
        .else
        ld      *sp(8), A
        .endif
	bcd	NoScale, AEQ
	ld	#0, ASM
	nop
	ld	#-2, ASM

        rptb    Stg1and2End    ;(N/4)*28+3
        dld     *ar2, B         ;B=R1                           R1
        dsub    *ar3, B         ;B=R1-R2                        R2
        dld     *ar2, A         ;A=R1                           R1
        dadd    *ar3, A         ;A=R1+R2                        R2
        sth     B, ASM, *ar3+   ;R2H=R1-R2/4                    R2
        stl     B, ASM, *ar3-   ;R2L=R1-R2/4                    R2
        dld     *ar4, B         ;B=R3                           R3
        dadd    *ar5, B         ;B=R3+R4
        add     B, A            ;A=(R1+R2)+(R3+R4)
        sth     A, ASM, *ar2+   ;R1H'=((R1+R2)+(R3+R4))/4       R1
        stl     A, ASM, *ar2+   ;R1L'=((R1+R2)+(R3+R4))/4       I1
        sub     B, 1, A         ;A=(R1+R2)-(R3+R4)
        dld     *ar4, B         ;B=R3                           R3
        dsub    *ar5, B         ;B=R3-R4                        R4
        sth     A, ASM, *ar4+   ;R3H'=((R1+R2)-(R3+R4))/4       I3
        stl     A, ASM, *ar4+   ;R3L'=((R1+R2)-(R3+R4))/4       I3
        dld     *ar3, A         ;A=(R1-R2)/4                    R2
        sth     B, ASM, *ar5+   ;R4H=(R3-R4)/4                  R4
        stl     B, ASM, *ar5+   ;R4L=(R3-R4)/4                  I4
        dld     *ar4, B         ;B=I3                           I3
        dsub    *ar5-, B        ;B=I3-I4                        R4
        add     B, ASM, A       ;A=((R1-R2)+(I3-I4))/4
        dst     A, *ar3+        ;R2'=((R1-R2)+(I3-I4))/4        I2
        sub     B, -1, A        ;A=((R1-R2)-(I3-I4))/4
        dld     *ar5, B         ;B=(R3-R4)/4                    R4
        dst     A, *ar5+        ;R4'=((R1-R2)-(I3-I4))/4        I4
        dld     *ar4, A         ;A=I3                           I3
        dadd    *ar5, A         ;A=I3+I4                        I4
        sth     A, ASM, *ar4+   ;I3H=(I3+I4)/4                  I3
        stl     A, ASM, *ar4-   ;I3L=(I3+I4)/4                  I3
        dld     *ar2, A         ;A=I1                           I1
        dsub    *ar3, A         ;A=I1-I2                        I2
        add     B, 2, A         ;A=(I1-I2)+(r3-r4)
        sth     A, ASM,*ar5+    ;I4H'=((I1-I2)+(r3-r4))/4       I4
        stl     A, ASM,*ar5+0   ;I4H'=((I1-I2)+(r3-r4))/4       next R4
        sub     B, 3, A         ;A=(I1-I2)-(r3-r4)
        dld     *ar2, B         ;B=I1                           I1
        dadd    *ar3, B         ;B=I1+I2                        I2
        sth     A, ASM, *ar3+   ;I2H'=(I1-I2)-(R3-R4)/4         I2
        stl     A, ASM, *ar3+0  ;I2H'=(I1-I2)-(R3-R4)/4         next R2
        dld     *ar4, A         ;A=(I3+I4)/4                    I3
        add     A, 2, B         ;B=(I1+I2)+(I3+I4)
        sth     B, ASM, *ar2+   ;I1H'=(I1+I2)+(I3+I4)/4         I1
        stl     B, ASM, *ar2+0  ;I1H'=(I1+I2)+(I3+I4)/4         next R1
        sub     A, 3, B         ;B=(I1+I2)-(I3+I4)
        sth     B, ASM, *ar4+   ;I3'=((I1+I2)-(I3+I4))/4        I3
Stg1and2End
        stl     B, ASM, *ar4+0  ;I3'=((I1+I2)-(I3+I4))/4        next R3
	.if	__far_mode
        fret
        .else
        ret
        .endif


NoScale:
        rptb    NoScaleEnd      ;(N/4)*28+3
        dld     *ar2, B         ;B=R1                           R1
        dsub    *ar3, B         ;B=R1-R2                        R2
        dld     *ar2, A         ;A=R1                           R1
        dadd    *ar3, A         ;A=R1+R2                        R2
        sth     B, ASM, *ar3+   ;R2H=R1-R2                      R2
        stl     B, ASM, *ar3-   ;R2L=R1-R2                      R2
        dld     *ar4, B         ;B=R3                           R3
        dadd    *ar5, B         ;B=R3+R4
        add     B, A            ;A=(R1+R2)+(R3+R4)
        sth     A, ASM, *ar2+   ;R1H'=((R1+R2)+(R3+R4))         R1
        stl     A, ASM, *ar2+   ;R1L'=((R1+R2)+(R3+R4))         I1
        sub     B, 1, A         ;A=(R1+R2)-(R3+R4)
        dld     *ar4, B         ;B=R3                           R3
        dsub    *ar5, B         ;B=R3-R4                        R4
        sth     A, ASM, *ar4+   ;R3H'=((R1+R2)-(R3+R4))         I3
        stl     A, ASM, *ar4+   ;R3L'=((R1+R2)-(R3+R4))         I3
        dld     *ar3, A         ;A=(R1-R2)                      R2
        sth     B, ASM, *ar5+   ;R4H=(R3-R4)                    R4
        stl     B, ASM, *ar5+   ;R4L=(R3-R4)                    I4
        dld     *ar4, B         ;B=I3                           I3
        dsub    *ar5-, B        ;B=I3-I4                        R4
        add     B, ASM, A       ;A=((R1-R2)+(I3-I4))
        dst     A, *ar3+        ;R2'=((R1-R2)+(I3-I4))          I2
        sub     B, 1, A         ;A=((R1-R2)-(I3-I4))  
        dld     *ar5, B         ;B=(R3-R4)                      R4
        dst     A, *ar5+        ;R4'=((R1-R2)-(I3-I4))          I4
        dld     *ar4, A         ;A=I3                           I3
        dadd    *ar5, A         ;A=I3+I4                        I4
        sth     A, ASM, *ar4+   ;I3H=(I3+I4)                    I3
        stl     A, ASM, *ar4-   ;I3L=(I3+I4)                    I3
        dld     *ar2, A         ;A=I1                           I1
        dsub    *ar3, A         ;A=I1-I2                        I2
        add     B, A            ;A=(I1-I2)+(r3-r4)
        sth     A, ASM,*ar5+    ;I4H'=((I1-I2)+(r3-r4))         I4
        stl     A, ASM,*ar5+0   ;I4H'=((I1-I2)+(r3-r4))         next R4
        sub     B, 1, A         ;A=(I1-I2)-(r3-r4)
        dld     *ar2, B         ;B=I1                           I1
        dadd    *ar3, B         ;B=I1+I2                        I2
        sth     A, ASM, *ar3+   ;I2H'=(I1-I2)-(R3-R4)           I2
        stl     A, ASM, *ar3+0  ;I2H'=(I1-I2)-(R3-R4)           next R2
        dld     *ar4, A         ;A=(I3+I4)                      I3
        add     A, B            ;B=(I1+I2)+(I3+I4)
        sth     B, ASM, *ar2+   ;I1H'=(I1+I2)+(I3+I4)           I1
        stl     B, ASM, *ar2+0  ;I1H'=(I1+I2)+(I3+I4)           next R1
        sub     A, 1, B         ;B=(I1+I2)-(I3+I4)
        sth     B, ASM, *ar4+   ;I3'=((I1+I2)-(I3+I4))          I3
NoScaleEnd
        stl     B, ASM, *ar4+0  ;I3'=((I1+I2)-(I3+I4))          next R3
	.if	__far_mode
        fret
        .else
        ret
        .endif

;=============================================================================
; Function:     fftStage3
;
; Description:  Stage 3 of Complex Inverse FFT (double precision)
;
; Inputs:       None
;
; Outputs:      None
;
; Assumptions:  Output will be in place of input.
;
;=============================================================================
fftStage3:
	.if	__far_mode
	ld	*sp(10), A
        .else
        ld      *sp(8), A
        .endif
	ld	#-1, ASM
	nop
	xc	1, AEQ
        ld      #0, ASM        ;ASM=0
        rptb    fftStg3End-1   ;(N/8)*36+3


;!!!!! rptb occurs here
; Butterfly1
        dld     *ar3, A         ;A=QR                           QR
        dld     *ar2, B         ;B=PR                           PR
        dsub    *ar3, B         ;B=PR-QR                        QR
        sth     B, ASM, *ar3+   ;QRH=(PR-QR)/2                  QR
        stl     B, ASM, *ar3+   ;QRL=(PR-QR)/2                  QI
        add     A, 1, B         ;B=PR+QR
        sth     B, ASM, *ar2+   ;PRH=(PR+QR)/2                  PR
        stl     B, ASM, *ar2+   ;PRL=(PR+QR)/2                  PI
        dld     *ar3, A         ;A=QI                           QI
        dld     *ar3, B         ;B=QI                           QI
        dadd    *ar2, B         ;B=PI+QI                        PI
        sth     B, ASM, *ar2+   ;PI=(PI+QI)/2                   PI
        stl     B, ASM, *ar2+   ;PI=(PI+QI)/2                   PR+1
        sub     A, 1, B         ;B=PI-QI
        sth     B, ASM, *ar3+   ;QI=(PI-QI)/2                   QI
        stl     B, ASM, *ar3+   ;QI=(PI-QI)/2                   QR+1
; Butterfly2
;===== QR*W (Q31) =====
        ld      #0, A
        macsu   *ar4-, *ar3+, A ;QRH*WL                         QRL WH
        macsu   *ar3-, *ar4, A  ;QRH*WL + QRL*WH
        ld      A, -16, A       ;A>>16
        mac     *ar4+, *ar3+, A ;A=QR*W                         QR WL
        sth     A, *ar5+        ;Tempdw1=QR*W for later use
        stl     A, *ar5-
;======================
        mar     *ar3+           ;point to QI                    QI
;===== QI*W (Q31) =====
        ld      #0, B           ;QIH*WL                         QIL WH
        macsu   *ar4-, *ar3+, B ;QIH*WL + QIL*WH
        macsu   *ar3-, *ar4, B  ;A>>16
        ld      B, -16, B       ;A=QI*W                         QI WL
        mac     *ar4+, *ar3-, B ;A=QI*W                         QI
        sth     B, *ar6+        ;Tempdw2=QI*W for later use
        stl     B, *ar6-
;======================
        mar     *ar3-           ;point to QR again              QR
        add     B, A            ;A=QR*W + QI*W
        dadd    *ar2, A         ;A=PR+(QR*W + QI*W)             PR
        dld     *ar2, B         ;B=PR                           PR
        sth     A, ASM, *ar2+   ;PRH'=(PR+(QR*W + QI*W))/2      PR
        stl     A, ASM, *ar2+   ;PRL'=(PR+(QR*W + QI*W))/2      PI
        sub     B, A            ;A=(QR*W + QI*W)
        sub     A, B            ;B=PR-(QR*W + QI*W)
        sth     B, ASM, *ar3+   ;QRH'=(PR-(QR*W + QI*W))/2      QR
        stl     B, ASM, *ar3+   ;QRL'=(PR-(QR*W + QI*W))/2      QI

        dld     *ar6, B         ;B=QI*W
        dsub    *ar5, B         ;B=QI*W - QR*W
        dadd    *ar2, B         ;B=PI+(QI*W - QR*W)             PI
        dld     *ar2, A         ;A=PI                           PI
        sth     B, ASM, *ar2+   ;PIH'=(PI+(QI*W - QR*W))/2      PI
        stl     B, ASM, *ar2+   ;PIL'=(PI+(QI*W - QR*W))/2      PR+1
        sub     A, B            ;B=(QI*W - QR*W)
        sub     B, A            ;A=PI-(QI*W - QR*W)
        sth     A, ASM, *ar3+   ;QIH'=(PI-(QI*W - QR*W))/2      QI
        stl     A, ASM, *ar3+   ;QIL'=(PI-(QI*W - QR*W))/2      QR+1
; Butterfly3
        dld     *ar2+, A        ;A=PR                           PI
        dld     *ar2-, B        ;B=PI                           PR
        dsub    *ar3+, B        ;B=PI-QR                        QI
        dadd    *ar3-, A        ;A=PR+QI                        QR
        sth     A, ASM, *ar2+   ;PRH'=(PR+QI)/2                 PR
        stl     A, ASM, *ar2+   ;PRL'=(PR+QI)/2                 PI
        sth     B, ASM, *ar2+   ;PIH'=(PI-QR)/2                 PI
        stl     B, ASM, *ar2+   ;PIL'=(PI-QR)/2                 PR+1
        dadd    *ar3, B         ;B=PI                           QR
        dadd    *ar3+, B        ;B=PI+QR                        QI
        dsub    *ar3, A         ;A=PR                           QI
        dsub    *ar3-, A        ;A=PR-QI                        QR
        sth     A, ASM, *ar3+   ;QRH'=(PR-QI)/2                 QR
        stl     A, ASM, *ar3+   ;QRL'=(PR-QI)/2                 QI
        sth     B, ASM, *ar3+   ;QIH'=(PI+QR)/2                 QI
        stl     B, ASM, *ar3+   ;QIH'=(PI+QR)/2                 QR+1
; Butterfly4
;===== QR*W (Q31) =====
        ld      #0, A
        macsu   *ar4-, *ar3+, A ;QRH*WL                         QRL WH
        macsu   *ar3-, *ar4, A  ;QRH*WL + QRL*WH
        ld      A, -16, A       ;A>>16
        mac     *ar4+, *ar3+, A ;A=QR*W                         QRL WL
        sth     A, *ar5+        ;Tempdw1=QR*W for later use
        stl     A, *ar5-
;======================
        mar     *ar3+           ;point to QI                    QR
;===== QI*W (Q31) =====
        ld      #0, B           ;QIH*WL                         QIL WH
        macsu   *ar4-, *ar3+, B ;QIH*WL + QIL*WH
        macsu   *ar3-, *ar4, B  ;B>>16
        ld      B, -16, B       ;B=QI*W                         QI WL
        mac     *ar4+, *ar3-, B ;B=QI*W                         QI
        sth     B, *ar6+        ;Tempdw2=QI*W for later use
        stl     B, *ar6-
;======================
        mar     *ar3-           ;point to QR again              QR
        sub     B, A            ;A=QR*W - QI*W
        dadd    *ar2, A         ;A=PR+(QR*W - QI*W)             PR
        dld     *ar2, B         ;B=PR                           PR
        sth     A, ASM, *ar3+   ;QRH'=(PR+(QR*W + QI*W))/2      QR
        stl     A, ASM, *ar3+   ;QRL'=(PR+(QR*W + QI*W))/2      QI
        sub     B, A            ;A=QR*W - QI*W
        sub     A, B            ;B=PR-(QR*W - QI*W)
        sth     B, ASM, *ar2+   ;PRH'=((PR-(QR*W - QI*W))/2     PR
        stl     B, ASM, *ar2+   ;PRL'=((PR-(QR*W - QI*W))/2     PI
        dld     *ar5, B         ;B=QR*W
        dadd    *ar6, B         ;B=QR*W+QI*W
        drsub   *ar2, B         ;B=PI-(QR*W+QI*W)               PI
        dld     *ar2, A         ;A=PI                           PI
        sth     B, ASM, *ar2+   ;PIH'=(PI-(QR*W + QI*W))/2      PI
        stl     B, ASM, *ar2+0  ;PIL'=(PI-(QR*W + QI*W))/2      PR+1
        sub     A, B            ;B=-(QR*W + QI*W)
        sub     B, A            ;A=PI+(QR*W + QI*W)
        sth     A, ASM, *ar3+   ;QIH'=(PI+(QR*W + QI*W))/2      QI
        stl     A, ASM, *ar3+0  ;QIL'=(PI+(QR*W + QI*W))/2      QR+1
fftStg3End
	.if	__far_mode
        fret
        .else
        ret
        .endif

;=============================================================================
; Function:     fftStageX
;
; Description:  General radix 2 stage of Complex FFT (double precision)
;
; Inputs:       None
;
; Outputs:      None
;
; Assumptions:  Output will be in place of input.
;
;=============================================================================
;        .global fftStageX
fftStageX:
	.if	__far_mode
        mvdk    *SP(2),BRC
        .else
        mvdk    *SP(1),BRC
        .endif
        pshm    AR0             ;save current offset index
        mvmm    ar6,ar4         ;start of cosine in stage 'stg'
        mvmm    ar7,ar5         ;start of sine in stage   'stg'
	.if	__far_mode
        mvdk    *SP(4),AR0      ;offset index for butterfly optimization
        .else
        mvdk    *SP(3),AR0      ;offset index for butterfly optimization
        .endif

;===== Butterfly starts here =====
        dld     *ar2, B         ;B=PR                           PR
        dsub    *ar3, B         ;B=PR-QR                        QR
        dld     *ar3, A         ;A=QR                           QR
        sth     B, ASM, *ar3+   ;QRH'=(PR-QR)/2                 QR
        stl     B, ASM, *ar3+   ;QRL'=(PR-QR)/2                 QI
        add     A, 1, B         ;B=PR+QR
        sth     B, ASM, *ar2+   ;PRH'=(PR+QR)/2                 PR
        stl     B, ASM, *ar2+   ;PRL'=(PR+QR)/2                 PI
        dld     *ar3, A         ;A=QI                           QI
        dadd    *ar2, A, B      ;B=PI+QI                        PI
        sth     B, ASM, *ar2+   ;PIH'=(PI+QI)/2                 PI
        stl     B, ASM, *ar2+   ;PIH'=(PI+QI)/2                 PR+1
        sub     A, 1, B         ;B=PI-QI
        rptbd   BflyX           ;delayed block repeat
        sth     B, ASM, *ar3+   ;QIH'=(PI-QI)/2                 QI
        stl     B, ASM, *ar3+   ;QIH'=(PI-QI)/2                 QR+1
;!!!!! rptb starts here !!!!!
;===== QR*WR (Q31) =====
        ld      #0, B
        macsu   *ar4-, *ar3+, B ;QRH*WRL                        QRL WRH
        macsu   *ar3+, *ar4, B  ;QRH*WRL + QRL*WRH              QI WRH
	ld	B, -16, B	;B>>16
        ;>>16 INTEGRATED INTO QI*WI FOR OPTIMIZATION
        ;FINAL MAC HAS BEEN MOVED AFTER QI*WI FOR OPTIMIZATION
;======================
;===== QI*WI (Q31) =====
        ld      #0, A
        macsu   *ar5-, *ar3+, A ;QIH*WIL                        QIL WIH
        macsu   *ar3-, *ar5, A  ;QIH*WIL + QIL*WIH              QIH WIH
        ld      A, -16, A       ;A>>16
        mac     *ar5+, *ar3-, A ;A=QIH*WIH                      QRL WIL
;======================
        mar     *ar3-           ;point to QR again              QR
        mac     *ar4+, *ar3, B  ;B+=QRH*WRH=QR*WR               QR  WRL
	sub	A, B		;B = (QR*WR - QI*WI)
        dadd    *ar2, B         ;B=PR+(QR*WR - QI*WI)           PR
        dld     *ar2, A         ;A=PR                           PR
        sth     B, ASM, *ar2+   ;PRH'=(PR+(QR*WR - QI*WI))/2    PR
        stl     B, ASM, *ar2+   ;PRL'=(PR+(QR*WR - QI*WI))/2    PI
        sub     A, B            ;B=QR*WR - QI*WI
        sub     B, A            ;A=PR-(QR*WR - QI*WI)
;===== QR*WI (Q31) =====
        ld      #0, B
        macsu   *ar5-, *ar3+, B ;QRH*WIL                        QRL WIH
        macsu   *ar3+, *ar5, B  ;QRH*WIL + QRL*WIH              QIH WIH

;===== QI*WR (Q31) =====
        macsu   *ar4-, *ar3+, B ;QIH*WRL                        QIL WRH
        macsu   *ar3-, *ar4, B  ;QIH*WRL + QIL*WRH              QIH WRH
        ld      B, -16, B       ;B>>16
        mac     *ar4+0%,*ar3-,B ;B=QIH*WRH, next WRL            QIL WRL+1
	mar	*ar3-		;				QRH
        mac     *ar5+0%,*ar3,B  ;B=QRH*WIH, next WIL            QRH WIL+1
				;B=QIWR+QRWI
;======================
        sth     A, ASM, *ar3+   ;QRH'=(PR-(QR*WR - QI*WI))/2    QRL
        stl     A, ASM, *ar3+   ;QRL'=(PR-(QR*WR - QI*WI))/2    QIH
;======================

        dadd    *ar2, B         ;B=PI+(QI*WR+QR*WI)             PI
        dld     *ar2, A         ;A=PI                           PI
        sth     B, ASM, *ar2+   ;PIH'=(PI+(QI*WR+QR*WI))/2      QI
        stl     B, ASM, *ar2+   ;PIL'=(PI+(QI*WR+QR*WI))/2      QR+1
        sub     A, B            ;B=(QI*WR+QR*WI)
        sub     B, A            ;A=PI-(QI*WR+QR*WI)
        sth     A, ASM, *ar3+   ;QIH'=(PI-(QI*WR+QR*WI))/2      PI
BflyX   stl     A, ASM, *ar3+   ;QIL'=(PI-(QI*WR+QR*WI))/2      PR+1

        popm    AR0             ;restore offset index
        banzd   fftStageX, *ar1-
        mar     *ar2+0
        mar     *ar3+0
;!!!!! Branch occurs here !!!!!
	.if	__far_mode
        fret
        .else
        ret
        .endif


;=============================================================================
; Function:     fftButterfly
;
; Description:  General radix 2 butterfly of Complex FFT (double precision)
;
; Inputs:       None
;
; Outputs:      None
;
; Assumptions:  BRC has been initialized already.
;               Output will be in place of input.
;
;=============================================================================
;        .global fftButterfly
fftButterfly:
        dld     *ar2, B         ;B=PR                           PR
        dsub    *ar3, B         ;B=PR-QR                        QR
        dld     *ar3, A         ;A=QR                           QR
        sth     B, ASM, *ar3+   ;QRH'=(PR-QR)/2                 QR
        stl     B, ASM, *ar3+   ;QRL'=(PR-QR)/2                 QI
        add     A, 1, B         ;B=PR+QR
        sth     B, ASM, *ar2+   ;PRH'=(PR+QR)/2                 PR
        stl     B, ASM, *ar2+   ;PRL'=(PR+QR)/2                 PI
        dld     *ar3, A         ;A=QI                           QI
        dadd    *ar2, A, B      ;B=PI+QI                        PI
        sth     B, ASM, *ar2+   ;PIH'=(PI+QI)/2                 PI
        stl     B, ASM, *ar2+   ;PIH'=(PI+QI)/2                 PR+1
        sub     A, 1, B         ;B=PI-QI
        rptbd   BflyEnd         ;delayed block repeat
        sth     B, ASM, *ar3+   ;QIH'=(PI-QI)/2                 QI
        stl     B, ASM, *ar3+   ;QIH'=(PI-QI)/2                 QR+1

;!!!!! rptb starts here !!!!!
;===== QR*WR (Q31) =====
        ld      #0, B
        macsu   *ar4-, *ar3+, B ;QRH*WRL                        QRL WRH
        macsu   *ar3+, *ar4, B  ;QRH*WRL + QRL*WRH              QI WRH
	ld	B, -16, B	;B>>16
        ;>>16 INTEGRATED INTO QI*WI FOR OPTIMIZATION
        ;FINAL MAC HAS BEEN MOVED AFTER QI*WI FOR OPTIMIZATION
;======================
;===== QI*WI (Q31) =====
        ld      #0, A
        macsu   *ar5-, *ar3+, A ;QIH*WIL                        QIL WIH
        macsu   *ar3-, *ar5, A  ;QIH*WIL + QIL*WIH              QIH WIH
        ld      A, -16, A       ;A>>16
        mac     *ar5+, *ar3-, A ;A=QIH*WIH                      QRL WIL
;======================
        mar     *ar3-           ;point to QR again              QR
        mac     *ar4+, *ar3, B  ;B+=QRH*WRH=QR*WR               QR  WRL
	sub	A, B		;B = (QR*WR - QI*WI)
        dadd    *ar2, B         ;B=PR+(QR*WR - QI*WI)           PR
        dld     *ar2, A         ;A=PR                           PR
        sth     B, ASM, *ar2+   ;PRH'=(PR+(QR*WR - QI*WI))/2    PR
        stl     B, ASM, *ar2+   ;PRL'=(PR+(QR*WR - QI*WI))/2    PI
        sub     A, B            ;B=QR*WR - QI*WI
        sub     B, A            ;A=PR-(QR*WR - QI*WI)
;===== QR*WI (Q31) =====
        ld      #0, B
        macsu   *ar5-, *ar3+, B ;QRH*WIL                        QRL WIH
        macsu   *ar3+, *ar5, B  ;QRH*WIL + QRL*WIH              QIH WIH

;===== QI*WR (Q31) =====
        macsu   *ar4-, *ar3+, B ;QIH*WRL                        QIL WRH
        macsu   *ar3-, *ar4, B  ;QIH*WRL + QIL*WRH              QIH WRH
        ld      B, -16, B       ;B>>16
        mac     *ar4+0%,*ar3-,B ;B=QIH*WRH, next WRL            QIL WRL+1
	mar	*ar3-		;				QRH
        mac     *ar5+0%,*ar3,B  ;B=QRH*WIH, next WIL            QRH WIL+1
				;B=QIWR+QRWI
;======================
        sth     A, ASM, *ar3+   ;QRH'=(PR-(QR*WR - QI*WI))/2    QRL
        stl     A, ASM, *ar3+   ;QRL'=(PR-(QR*WR - QI*WI))/2    QIH
;======================

        dadd    *ar2, B         ;B=PI+(QI*WR+QR*WI)             PI
        dld     *ar2, A         ;A=PI                           PI
        sth     B, ASM, *ar2+   ;PIH'=(PI+(QI*WR+QR*WI))/2      QI
        stl     B, ASM, *ar2+   ;PIL'=(PI+(QI*WR+QR*WI))/2      QR+1
        sub     A, B            ;B=(QI*WR+QR*WI)
        sub     B, A            ;A=PI-(QI*WR+QR*WI)
        sth     A, ASM, *ar3+   ;QIH'=(PI-(QI*WR+QR*WI))/2      PI
BflyEnd	stl     A, ASM, *ar3+   ;QIL'=(PI-(QI*WR+QR*WI))/2      PR+1
	.if	__far_mode
        fret
        .else
        ret
        .endif