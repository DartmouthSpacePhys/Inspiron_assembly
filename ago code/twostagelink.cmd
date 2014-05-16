/* TMS320C542 DSP Board Boot Rom Linker Command File */

-e RXDSP_START

MEMORY {
PAGE 0:
	INTR_TABLE (RWX):	origin = 0x0080, length = 0x0080
	PROG_ANNEX (RIX):	origin = 0x0180, length = 0x0680
	PROG_MAIN (RIX) :	origin = 0x0C00, length = 0x1200

PAGE 1:
	STACK (RW)	:	origin = 0x0100, length = 0x0040
	TEMP_DATA (RW)	:	origin = 0x0140, length = 0x0040
	SBUFFER (RW)	:	origin = 0x0800, length = 0x0400
	SCALES (RW)		:	origin = 0x1E00, length = 0x0200
	DATA (RW)	:	origin = 0x2000, length = 0x0800
}

SECTIONS {
	.bl549		: load > PROG_ANNEX, align = 64
	.vectors	: load > INTR_TABLE
	.text		: load > (RIX)
	.cbrev_p 	: load > (RIX)
	.cfft_p		: load > (RIX)
	.log10_p	: load > (RIX)
	.smon_p		: load > (RIX)
	.smon_msg	: load > (RIX)
	.sine_tab	: load > (RI)
	.hann_tab	: load > (RI)
	.hann_p		: load > (RIX)
	.sercook_p	: load > (RIX)
	.ad6620		: load > (RIX)
	.transfer_p	: load > (RIX)
	.dpsm_p		: load > (RIX)
	.scale_p	: load > (RIX)
	
	/* data sections */
	.bss		: > TEMP_DATA
	.stack_v	: > STACK
	.sbuff_v	: > SBUFFER
	.scale_v	: > SCALES
	.data_v		: > DATA
}	
