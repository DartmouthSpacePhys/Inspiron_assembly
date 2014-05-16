************************************************************
*** Bootloader software version N0. : 1.0 ***
*** Last revision date : 10/23/1996 ***
*** Author : J. Chyan ***
************************************************************
************************************************************
** **
** Boot Loader Program **
** **
** This code segment sets up and executes boot loader **
** code based upon data saved in data memory **
** **
** WRITTEN BY: Jason Chyan **
** DATE: 06/06/96 **
** **
** Revision History **
** 1.0 Change HPI boot from c542 boot loader **
** Implement Paralle Boot (EPROM) YGC 06/07/96 **
** **
** 1.1 Implement Serial Port Boot YGC 06/17/96 **
** 1.2 Implement I/O Boot YGC 06/20/96 **
** 1.3 Add A–law, u–law, sinwave and **
** interrupt vectors table YGC 06/25/96 **
** 1.4 Registers reprogrammable in I/O mode YGC 06/25/96 **
** 1.5 Implement TDM mode & ABSP mode YGC 10/23/96 **
** 1.6 Fix the SP (steak point) bug YGC 10/24/96 **
** 1.7 Fix the BSP bug YGC 01/16/96 **
** 1.8 Fix the dest. address in par8/16 TNG 03/24/96 **
** 1.9 Fix the bugs in BSP/ABU mode TNG 08/28/97 **
** 1.91 Fix the hi byte bug in par8 mode TNG 12/10/97 **
* 1.92 Fix the par8 mode bug PMJ2 11/09/98 **
************************************************************

************************************************************
.title ”bootc54LP”
**********************************************************
* symbol definitions
**********************************************************
.mnolist
.def boot
.def endboot
.def bootend
.def dest
.def src
.def lngth
.def hbyte
* .ref boota ; reserved for ROM Code customer
boota .set 0184h ; Arbitrary ref (for USR bootcode)
* Conditional Assembly Flags
HPIB .set 1
LC548 .set 1
*
pa0 .set 0h ; port address 0h for i/o boot load
brs .set 60h ; boot routine select (configuration word)
xentry .set 61h ; XPC of entry point
entry .set 62h ; entry point
hbyte .set 63h ; high byte of 8–bit serial word
p8word .set 64h ; concatenator for 8–bit memory load
src .set 65h ; source address
dest .set 66h ; destination address (dmov from above)
lngth .set 67h ; code length
temp0 .set 68h ; temporary register0
temp1 .set 69h ; temporary register1
temp2 .set 6ah ; temporary register2
temp3 .set 6bh ; temporary register3
nmintv .set 6ch ; non–maskable interrupt vector
sp_ifr .set 6dh ; SP IFR temp reg
* MMR definition for c54xlp CPU register
**
ifr .set 01h
st1 .set 07h
BL .set 0bh
brc .set 1ah
pmst .set 1dh



* * * * * * * * * * * * * * * * * * * * * * * * *
*	Bootload from 8–bit memory, MS byte first	*
* * * * * * * * * * * * * * * * * * * * * * * * *

par08
	ld		*ar1+, 8, a 	; load accumulator A MSB of SWWSR value
	mvdk	*ar1+, ar3 		; ar3	<-- junkbyte.low
	andm	#0ffh, @ar3 	; ar3	<-- low byte
	or		@ar3, a 		; acc A <-- high byte.low byte
	stlm	a,swwsr			; stor A to SWWSR
	
	ld		*ar1+, 8, a 	; load accumulator A MSB of BSCR value
	mvdk	*ar1+, ar3 		; ar3	<-- junkbyte.low byte
	andm	#0ffh, @ar3 	; ar3	<-- low byte
	or		@ar3, a			; acc A <-- high byte.low byte
	and		#0FFFEh,a 		; ensure EXIO bit is off
	stlm	a,bscr			; stor A to BSCR
	
	ld		*ar1+, 8, a 	; load accumulator A MSB of XPC of entry 
	mvdk	*ar1+, ar3		; ar3	<-- junkbyte.low byte 
	andm	#0ffh, @ar3		; ar3	<-- low byte 
	or		@ar3, a			; acc A <-- high byte.low byte 
	stl		a, @xentry		; stor A to xentry

	ld		*ar1+, 8, a 	; load accumulator A MSB of entry
	mvdk	*ar1+, ar3 		; ar3	<-- junkbyte.low byte
	andm	#0ffh, @ar3 	; ar3	<-- low byte
	or		@ar3, a			; acc A <-- high byte.low byte
	stl		a, @entry		; stor A to entry
	
par08_1				; Main section load loop

	ld	*ar1+, 8, a 		; get number of 16-bit words
	and	#0FF00h,a 			; Clear the guard bits and keep low accum (1.92)
	mvdk	*ar1+, ar3 		; ar3	<-- junkbyte.low byte
	andm	#0ffh, @ar3 	; ar3	<-- low byte
	or	@ar3, a 			; acc A	<-- high byte.low byte
	bcd	endboot,aeq 		; section size = 0 indicates boot end
	
	sub	#1,a,b 				; brc = section size - 1
	stlm	b, brc 			; update block repeat counter register
	ld	*ar1+, 8, a			; get XPC of destination
	mvdk	*ar1+, ar3		; ar3	<-- junkbyte.low byte
	andm	#0ffh, @ar3		; ar3	<-- low byte
	or	@ar3, a 			; acc A	<-- high byte.low byte
	stl	a,@dest 			; @dest <-- XPC
	ld	*ar1+, 8, a			; get address of destination
************* Bug fix ****************************************************** 
	and	#0ff00h,a	;force AG, AH to zero for correct calculation
					;of the 23–bit destination address. (10/14/99 BCT)
****************************************************************************
	mvdk	*ar1+, ar3 		; ar3	<-- junkbyte.low byte
	andm	#0ffh, @ar3 	; ar3	<-- low byte
	or		@ar3, a 		; acc A	<-- high byte.low byte
	stlm	a,ar2			; ar2	<-- destination address
	
	rptb 	xfr08–1 ; block repeat, load this section's data
	ld	*ar1+, 8, a 		; acc A	<-- high byte
	mvdk	*ar1+, ar3 		; ar3	<-- junkbyte.low byte
	andm	#0ffh, @ar3 	; ar3	<-- low byte
	or	@ar3, a 			; acc A	<-- high byte.low byte
	stl	a, @p8word 
	ldu	@ar2,a 				; load XPC to acc AH
	add	@dest,16,a			; acc A <-- destination address
	nop			; 10 cycles betwixt read & write
	writa	@p8word			; write object data to destination
	add		#1, a
	stlm	a, ar2			; update destination address
xfr08				; end block repeat

	b		par08_1	; end section loop
	
**
*	End 549 8-bit EPROM bootloader
**

endboot
	ldu 	@entry, a 		; branch to the entry point
	add 	@xentry, 16, a 	;
	bacc a
