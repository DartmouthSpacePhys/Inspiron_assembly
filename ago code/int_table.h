;
;	Interrupt Vectors, RAM Page 1
;

	.sect	.vectors
;	.label	_int_vect_start
	
int_table:
	b	ago_main		; Reset/SINTR 0
	nop
	nop
;
	b	nmi_int			; NMI/SINT16 1
	nop
	nop
;
	b	ago_main		; SINT17 2
	nop
	nop
;
	b	ago_main		; SINT18 3
	nop
	nop
;
	b	ago_main		; SINT19 4
	nop
	nop
;
	b	ago_main		; SINT20 5
	nop
	nop
;
	b	ago_main		; SINT21 6
	nop
	nop
;
	b	ago_main		; SINT22 7
	nop
	nop
;
	b	ago_main		; SINT23 8
	nop
	nop
;
	b	ago_main		; SINT24 9
	nop
	nop
;
	b	ago_main		; SINT25 10
	nop
	nop
;
	b	ago_main		; SINT26 11
	nop
	nop
;
	b	ago_main		; SINT27 12
	nop
	nop
;
	b	ago_main		; SINT28 13
	nop
	nop
;
	b	ago_main		; SINT29 14
	nop
	nop
;
	b	ago_main		; SINT30 15
	nop
	nop
;
	b	ago_main		; INT0/SINT0 16
	nop
	nop
;
	b	ago_main		; INT1/SINT1 17
	nop
	nop
;
	b	ago_main		; INT2/SINT2 18
	nop
	nop
;
	b	ago_main		; TINT/SINT3 19 (just returns)
;	b	minor_int	; Test code with timer
	nop
	nop
;
	b	ago_main		; BRINT0/SINT4 20
	nop
	nop
;
	b	ago_main		; BXINT0/SINT5 21
	nop
	nop
;
	b	ago_main		; TRINT0/SINT6 22
	nop
	nop
;
	b	ago_main		; TXINT0/SINT7 23
	nop
	nop
;
	b	ago_main		; INT3/SINT8 24
	nop
	nop
;
	b	ago_main		; HPINT/SINT9 25
	nop
	nop
;		
	b	ago_main		; Reserved vector 26
	nop
	nop
;		
	b	ago_main		; Reserved vector 27
	nop
	nop
;		
	b	ago_main		; Reserved vector 28
	nop
	nop
;		
	b	ago_main		; Reserved vector 29
	nop
	nop
;		
	b	ago_main		; Reserved vector 30
	nop
	nop
;		
	b	ago_main		; Reserved vector 31
	nop
	nop

	.label	_int_vect_end