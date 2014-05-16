abu_buff_loc	.set	0		; serial buffer start location
abu_buff_sz		.set	100		; size of serial buffer (2x burst size)

;
; Interrupt flag bit masks: TMS320C542 nomenclature
;
int_0	.set	0001h		; Interrupt 0 (major)
int_1	.set	0002h		; Interrupt 1 (minor)
int_2	.set	0004h		; Interrupt 2 (word- not used- boot-up issues)
int_t	.set	0008h		; Timer (for test purposes)
int_br	.set	0010h		; BSP receive int
int_bx	.set	0020h		; BSP transmit int
int_tr	.set	0040h		; TSP receive int
int_tx	.set	0080h		; TSP transmit int
int_3	.set	0100h		; Interrupt 3 (Aux)

; Buffered Serial Port Control Register bit definitions

bspc_dlb	.set	2		; digital loopback
bspc_fo		.set	4		; format
bspc_fsm	.set	8		; frame sync mode
bspc_mcm	.set	16		; clock mode
bspc_txm	.set	32		; transmit mode
bspc_nXrst	.set	64		; transmit reset
bspc_nRrst	.set	128		; receive reset
bspc_in0	.set	256		; binary state of receive clock line (r/o)
bspc_in1	.set	512		; binary state of transmit clock line (r/o)
bspc_Rrdy	.set	1024	; receive ready (r/o)
bspc_Xrdy	.set	2048	; transmit ready (r/o)
bspc_XSRfull .set	4096	; Transmit Shift Register full (r/o)
bspc_RSRfull .set	8192	; Receive Shift Register full (r/o)
bspc_Soft	.set	16384	; HLL debugging clock behavior bit
bspc_Free	.set	32768	; HLL debugging clock behavior bit

; Buffered Serial Port Control Extension Register bit definitions

; bits 0-4 are the clock division bits
bspce_fsp	.set	32		; frame sync polarity
bspce_clkp	.set	64		; clock polarity
bspce_fe	.set	128		; format extension
bspce_fig	.set	256		; continuous mode frame sync ignore
bspce_pcm	.set	512		; pulse code modulation mode
bspce_bxe	.set	1024	; autobuffer transmit enable
bspce_xh	.set	2048	; autobuffer transmit half completed (r/o)
bspce_haltx	.set	4096	; autobuffer transmit half halt
bspce_bre	.set	8192	; autobuffer receive enable
bspce_rh	.set	16384	; autobuffer receive half completed (r/o)
bspce_haltr	.set	32768	; autobuffer receive half halt

read_init:

	stm		#(bspc_fsm), BSPC0 		; reset BSP
	stm		#(int_br+int_bx), IFR	; clear serial interrupts
	stm		#(int_bx), IMR			; unmask serial interrupts
	rsbx	INTM ; global interrupt enable
	stm		#(bspce_fe+bspce_bxe), BSPCE0	; 10-bit words, enable tx autobuffer
	stm		#(abu_buff_loc), AXR	
	stm		#(abu_buff_sz), BKX
	
	;
	; Write out header
	;
	
	
	
	;
	; Start BSP transmits
	;
	
	stm		#(bscp_fsm+bspc_nXrst), BSPC0	; have to hold fsm bit
	
	

	; after IDLE
	
	stm		#1, AR7
	
	<data loop>
	
	cmpm	AR7, #burst_size	; see if we're done with this data burst
	bcd		rx_read_loop, NTC
	mar *AR7+
	nop
