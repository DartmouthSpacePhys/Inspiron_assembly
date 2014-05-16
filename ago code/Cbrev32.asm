;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;*****************************************************************************
;  Function:	cbrev32
;  Description: 32-bit complex bit-reverse routine (C54x)
;
;  Copyright Texas instruments Inc, 1998
;-----------------------------------------------------------------------------
;  Revision History:
;  1.00Beta  A. Aboagye, 10/15/98. Original release.
;			from cbrev code by R. Piedra.
;*****************************************************************************

        .mmregs

	.if __far_mode
offset	.set 1
	.else
offset	.set 0
	.endif
					; stack description
	.asg	(0), ret_addr

					; x in A
	.asg	(3+ offset), arg_y
	.asg	(4+ offset), arg_n

					; register usage
					; ar0 : bit reversing idx
	.asg	ar2,ar_dst
	.asg	ar3,ar_src

	.global     _cbrev32
;        .text
	.sect	".cbrev_p"

_cbrev32

        PSHM    ST0                                 ; 1 cycle
        PSHM    ST1                                 ; 1 cycle
	ssbx	CPL
        RSBX    OVA                                 ; 1 cycle
        RSBX    OVB                                 ; 1 cycle

; Get arguments
; -------------
	stlm	a, ar_src		; pointer to src		(1)
	mvdk	*sp(arg_y), *(ar_dst)	; pointer to dst (temporary)	(2)
	ld	*sp(arg_n), a		; a = n 			(1)
	sfta	a,1
	stlm	a, AR0			; AR0 = n = 1/2 size of circ buffer (1)
	sfta	a,-1
	sub	#3,a			; a = n-3(by pass 1st and last elem)(2)

; Select in-place or off-place bit-reversing
; ------------------------------------------

	ldm	ar_src,b		; b = src_addr			(1)
	sub	*sp(arg_y),b		; b = src_addr - dst_addr	(1)

	bcd	in_place, beq		; if (ar_src==ar_dst)then in_place (2)
	stlm	a, brc			; brc = n-3			(1)
	nop				;				(1)

; Off-place bit-reversing
; -----------------------

off_place:
_start1:
					; unroll to fill delayed slots
	rptb	off_place_end-1 	;				(2)
	mvdd	*ar_src+,*ar_dst+	; move high real component	(1)
	mvdd	*ar_src+,*ar_dst+	; move low real component	(1)
	mvdd	*ar_src+,*ar_dst+	; move high Im component	(1)
	mvdd	*ar_src-,*ar_dst+	; move low Im component		(1)
	mar	*ar_src-
	mar	*ar_src-
	mar	*ar_src+0B		;				(1)
off_place_end:
	b	end			;				(2)


; In-place bit-reversing
; ----------------------

in_place:

	mar	*ar_src+0B		; bypass first and last element (1)
	mar	*+ar_dst(4)		;				(1)
_start2:
	rptbd	in_place_end-1		;				(2)
	ldm	ar_src,a		; b = src_addr			(1)
	ldm	ar_dst, b		; a = dst_addr			(1)


	sub	b,a			; a =  src_addr  - dst_addr		(1)
					; if >=0  bypass move just increment
	bcd	bypass, ageq		; if (src_addr>=dst_addr) then skip	(2)
	dld	*ar_dst+, a		; a = Re dst element (preserve) 	(1)
	dld	*ar_dst-, b		; b = Im dst element (preserve)		(1)

	mvdd	*ar_src+, *ar_dst+	; high Re dst = high Re src		(1)
	mvdd	*ar_src+, *ar_dst+	; low Re dst = low Re src		(1)
	mvdd	*ar_src+, *ar_dst+	; high Im dst = high Im src;point to Re	(1)
	mvdd	*ar_src-, *ar_dst-	; low Im dst = low Im src;point to Re	(1)
	mar	*ar_dst-
	mar	*ar_dst-
	dst	b, *ar_src-		; Im src = b = Im dst;point to Re 	(1)
	dst	a, *ar_src		; Re src = a = Re dst			(1)

bypass
	mar	*ar_src+0B		;				(1)
	mar	*+ar_dst(4)		;				(1)
	ldm	ar_src,a		; b = src_addr			(1)
	ldm	ar_dst, b		; a = dst_addr			(1)
in_place_end



; Return
; ------

_end:
end
        POPM    ST1                                 ; 1 cycle
        POPM    ST0                                 ; 1 cycle

	.if	__far_mode
	fretd
	.else
	retd
	.endif
	nop
        nop

;end of file. please do not remove. it is left here to ensure that no lines of code are removed by any editor
