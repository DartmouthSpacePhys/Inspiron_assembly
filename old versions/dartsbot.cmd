/* TMS320C542 DSP Board Boot Rom Generation Command File */
/* 19 Dec. 2009 updated for c: drive */
/* 01 Nov. 2006 */
/* Dartmouth SLAVE Boot PROM Generation */
/* Use: hex500 a:\dartsbot.cmd */
c:\dspt\darts11.out		/* Input file */
-o c:\dspt\darts11.hex	/* Output file */
-i				/* Intel format */
-memwidth 8		/* 8-bit memory */
-romwidth 8		/* 8-bit EEPROM, bytes */
-bootorg 0x0000	/* External data memory boot */

SECTIONS {.text: BOOT}
