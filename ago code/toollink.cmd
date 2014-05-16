/* TMS320C542 DSP Board Boot Rom Linker Command File */

MEMORY {
	INTR_TABLE (RWX):	origin = 0x0080, length = 0x0080
	STACK (RW)	:	origin = 0x0100, length = 0x0100
	PROG_MAIN (RIX)	:	origin = 0x0200, length = 0x0600
	SBUFFER (RW)	:	origin = 0x0800, length = 0x0400
	PROG_MINI (RIX) :	origin = 0x0C00, length = 0x0400
	DATA (RW)	:	origin = 0x1000, length = 0x0800
	PROG_ANNEX (RIX)	:	origin = 0x1800, length = 0x1000

/*	INTR_TABLE (RIX):	origin = 0x0080, length = 0x0080
	PROG_MAIN (RIX)	:	origin = 0x0100, length = 0x0700
	SBUFFER (RW)	:	origin = 0x0800, length = 0x0400
	PROG_MINI (RIX)	:	origin = 0x0c00, length = 0x0400
	DATA (RW)	:	origin = 0x1000, length = 0x0800
	PROG_ANNEX (RIX):	origin = 0x1800, length = 0x0F00
	STACK (RW)	:	origin = 0x2700, length = 0x0100*/
}

SECTIONS {
	/* default section map
	.text:	PAGE = 0
	.data:	PAGE = 0
	.cinit:	PAGE = 0 ; cflag option only
	.bss:	PAGE = 1
	*/

	.text : > (RIX) {
		*.obj(*)
	}
	
/*	_int_vect	: load > EPROM	run > INTR_TABLE
	.text		: load > EPROM	run > PROGRAM
	_cbrev_p 	: load > EPROM	run > (RIX)
	_cfft_p		: load > EPROM	run > (RIX)
	_log10_p	: load > EPROM	run > (RIX)	
	_smon_p		: load > EPROM	run > (RIX)
	.sintab		: load > EPROM	run > (RIX)*/
}	
