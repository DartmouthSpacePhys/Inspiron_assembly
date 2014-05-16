/* TMS320C542 DSP Board Boot Rom Generation Command File */
/* 19 Dec. 2009- updated for c: drive */ 
/* 01 Nov. 2006 */
/* Dartmouth MASTER Rx-DSP Boot PROM Generation */

-memwidth 8
-romwidth 8
-boot			/* Convert all COFF sections to hex */
-bootorg 0x0000		/* External data memory boot */

ROMS {
	EPROM1: origin=0x0000, length=0x8000, memwidth=8, romwidth=8
}
