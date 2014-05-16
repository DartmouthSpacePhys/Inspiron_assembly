;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;*********************************************************************************
;  Function:	log_10
;  Description: Calculate log of 16-bit Q15 number
;
;  Copyright Texas instruments Inc, 1998
;--------------------------------------------------------------------------------
; Revision History:
;  1.00, A. Aboagye, 8/31/98 - Original release. Started from code by P. Dorster
;  1.10, A. Aboagye, 10/6/99 - Fixed far mode bug - replaced *SP(17) with *SP(17+offset)
;  1.20, A. Aboagye, 04/27/00 - Fixed "SXM not set" bug
;********************************************************************************

	.asg    *sp(0), x_ptr
	.asg    *sp(1), Exp
	.asg    *sp(2), Mant
	.asg    *sp(3), U
	.asg    *sp(4), Temp
	.asg    *sp(5), CST_4000
	.asg    *sp(6), LB6
	.asg    *sp(7), LB5
	.asg    *sp(8), LB4
	.asg    *sp(9), LB3
	.asg    *sp(10), LB2
	.asg    *sp(11), LB1
	.asg    *sp(12), LB0
	.asg    *sp(13), CST_1
	.asg    *sp(14), CST_ln2
		; 15 = ST1, 16 = ST0, 17 = function return pointer
	.asg    *sp(18), y_ptr
		; nx (array size) at *sp(19+offset)

	.mmregs		; assign Memory-Mapped Register names as global symbols
	.def		_log_10

;	.text		; begin assembling into .text section
	.sect	".log10_p"
	
_log_10:
        PSHM    ST0                                 ; 1 cycle
        PSHM    ST1                                 ; 1 cycle
        ssbx	CPL
        RSBX    OVA                                 ; 1 cycle
        RSBX    OVB                                 ; 1 cycle

	FRAME	#-15
	nop
**initialization for Logarithm calculation                                     

        RSBX    FRCT
        SSBX    SXM
	ST	#04000h,CST_4000
	ST	#0DC56h,LB6
	ST	#54adh,LB5
	ST	#9e8ah,LB4
	ST	#50d5h,LB3
	ST	#0c056h,LB2
	ST	#3ffdh,LB1
	ST	#062dh,LB0
	ST	#58B9h,CST_ln2		
	ST	#1h,CST_1
	STL	A, x_ptr

	LD	*SP(19), A
	SUB     #1,A
	STLM    A,BRC      
	MVDK	y_ptr, *(AR4)
	MVDK	x_ptr, *(AR3)

	RPTB	endlog
**************
* Normalize x
**************

	LD		*AR3+,16,A		; A = x<<16
	EXP		A		; T = number of leading bits
	ST		T,Exp		; Exp = number of leading bits
	NORM	A			; A = A<<T
	STH		A,Mant		; Mant = M (between 0.5 and 1.0)

***************************
* Polynomial approximation 
***************************
   
	LDM		SP, A
	ADD		#5, A
	STLM		A, AR2	
	;STM		#CST_4000,AR2
	LD		Mant,1,A	; A <- 2*M  
	SUB		*AR2+,1,A	; A <- (2*M-1) Q15 
	STLM		A,T  		; U <- (2*M-1) Q15 (between 0.0 and 1.0)           
	LD		*AR2+,16,A
	LD		*AR2+,16,B 
	POLY		*AR2+		; A(32-16) <- B6*U + B5
					; Q34 + Q18<<16 = Q34				
	POLY		*AR2+          	; A <- (B6*U + B5)*U + B4
					; Q33 + Q17<<16 = Q33					
	POLY		*AR2+		; A <- ((B6*U + B5)*U + B4)*U + B3
					; Q32 + Q16<<16 = Q32							
	POLY		*AR2+	       	;  A <- (((B6*U + B5)*U + B4)*U + B3)*U + B2
					; Q31 + Q15<<16 = Q31                               							
	POLY		*AR2           	; A <- ((((B6*U + B5)*U + B4)*U + B3)*U + B2)*U + 
 					; B1
					; Q30 + Q14<<16 = Q30							
	SFTA		A,1,A		; Q14<<1 = Q15 (accumulator high)	
	MPYA		A										
	ADD		*AR2+,A		; A <- (((((B6*U + B5)*U + B4)*U + B3)*U + B2)*U + 
 					; B1)*U + B0
					; Q30 + Q30 = Q30                                               
	STH		A,1,Temp	; Temp <- (((((B6*U + B5)*U + B4)*U + B3)*U + B2)*U  + B1)*U + B0
					; = f(2*M-1)
					; Q14<<1 = Q15 (accumulator high)					
*******************
* Process exponent
*******************

	LD		Exp,A		; A <- number of leading bits
	NEG		A		; A <- exponent = P
	SUB		*AR2+,A		; A <- P-1                
	STLM		A,T         	; T <- P-1
	MPY		*AR2,A		; A <- (P-1)*ln(2)
					; Q0*Q15 = Q15
                                  
*************************
* Add both contributions
*************************

	ADD		Temp,A		; A <- f(2*M(x)-1) + (P(x)-1)*ln(2)
	LD		A, B
	AND		#7FFFh, B
	STL		B, *AR4
	STM		#03797h, T
	SSBX		FRCT
	nop
	SFTA		A, 1
	MPYA		A
	MPY		*AR4, B
	SFTA		A, -1
	SFTA		B, -16
	ADD		B, A
	DST		A, *AR4+
endlog	RSBX		FRCT

************************
* Return overflow flag
************************

	FRAME		#15
	LD		#0,A
	XC		1,AOV
	LD		#1,A
        POPM    ST1
        POPM    ST0

        RET                                      ; 5 cycles

;end of file. please do not remove. it is left here to ensure that no lines of code are removed by any editor
