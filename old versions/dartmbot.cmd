/* TMS320C542 DSP Board Boot Rom Generation Command File */
/* 19 Dec. 2009- updated for c: drive */ 
/* 01 Nov. 2006 */
/* Dartmouth MASTER Rx-DSP Boot PROM Generation */
/* Use: hex500 a:\dartmbot.cmd */
dartm11.out             /* Input file */
-o dartm11.hex  /* Output file */
-i				/* Intel format */
-memwidth 8		/* 8-bit memory */
-romwidth 8		/* 8-bit EEPROM, bytes */
-bootorg 0x0000	/* External data memory boot */

SECTIONS {.text: BOOT}
