;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;*****************************************************************************
;  Function:	cbrev
;  Description: complex bit-reverse routine (C54x)
;
;  Copyright Texas instruments Inc, 1998
;-----------------------------------------------------------------------------
;  Revision History:
;  1.00  R. Piedra, 8/31/98. Original release.
;  1.10  A. Aboagye, 10/7/99  - Removed setting of sign extension mode bit
;*****************************************************************************

    .mmregs
    .def _cbrev
    
	; address in A
	; N in B (number of I/Q pairs)

	; register usage
	; ar0 : bit reversing idx
	.asg	ar3,ar_src
	.asg	ar2,ar_dst

;	.global     _cbrev
;	.text
	.sect	".cbrev_p"

_cbrev

	ssbx	XF
	rpt		#30000
	nop
	rsbx	XF
	

	PSHM    ST0                                 ; 1 cycle
	PSHM    ST1                                 ; 1 cycle
	RSBX    OVA                                 ; 1 cycle
	RSBX    OVB                                 ; 1 cycle

	rsbx	sxm			;				(1)

; Get arguments
; -------------
	stlm	a, ar_src		; pointer to src		(1)
	stlm	a, ar_dst
	stlm	b, AR0			; AR0 = n = 1/2 size of circ buffer (1)

	sub	#3,b			; b = n-3(by pass 1st and last elem)(2)

	stlm	b, brc			; brc = n-3			(1)
	nop				;				(1)

; In-place bit-reversing
; ----------------------

in_place:

	mar	*ar_src+0B		; bypass first and last element (1)
	mar	*+ar_dst(2)		;				(1)
_start2:
	rptbd	in_place_end-1		;				(2)
	ldm	ar_src,a		; b = src_addr			(1)
	ldm	ar_dst, b		; a = dst_addr			(1)



	sub	b,a			; a =  src_addr  - dst_addr	(1)
					; if >=0  bypass move just increment
	bcd	bypass, ageq		; if (src_addr>=dst_addr) then skip(2)
	ld	*ar_dst+, a		; a = Re dst element (preserve) (1)
	ld	*ar_dst-, b		; b = Im dst element (preserve) (1)

	mvdd	*ar_src+, *ar_dst+	; Re dst = Re src		(1)
	mvdd	*ar_src , *ar_dst-	; Im dst = Im src;point to Re	(1)
	stl	b, *ar_src-		; Im src = b = Im dst;point to Re (1)
	stl	a, *ar_src		; Re src = a = Re dst		(1)

bypass:
	mar	*ar_src+0B		;				(1)
	mar	*+ar_dst(2)		;				(1)

	ldm	ar_src,a		; b = src_addr			(1)
	ldm	ar_dst, b		; a = dst_addr			(1)

in_place_end:

	rpt		#30000
	nop
	ssbx	XF
	rpt		#30000
	nop
	rsbx	XF
	rpt		#30000
	nop
	ssbx	XF
	rpt		#30000
	nop
	rsbx	XF
	rpt		#30000
	nop
	ssbx	XF
	rpt		#30000
	nop
	rsbx	XF
	rpt		#30000
	nop


; Return
; ------

        POPM    ST1                                 ; 1 cycle
        POPM    ST0                                 ; 1 cycle
        
    nop
    nop
	retd
	nop
	nop

;end of file. please do not remove. it is left here to ensure that no lines of code are removed by any editor
