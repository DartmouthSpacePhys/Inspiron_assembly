;
; System-specific constants
;
npmst	.set	0000000010100011b
				; Processor mode and status
				; IPTR to page 1 (9 MSBs)
				; MP/MC = 0, microcontroller
				; OVLY = 1
				; AVIS = 0
				; DROM = 0
				; CLKOFF = 0 (CLKOUT is active)
				; SMUL = 1
				; SST = 1
defst0	.set	0001100000000000b
				; ARP = 0
				; TC =  1
				; C = 1
				; OVA = 0
				; OVB = 0
				; DP = 0
defst1	.set	0010100100000000b
				; BRAF = 0
				; CPL = 0
				; XF = 1
				; HM = 0
				; INTM = 1
				; 0
				; OVM = 0
				; SXM = 1
				; C16 = 0
				; FRCT = 0
				; CMPT = 0
				; ASM = 0

prom		.set	8000h		; EEPROM base address
scratch		.set	0060h		; Scratchpad RAM 0060h - 007Fh
stack		.set	013Fh		; Stack pointer to high ram
;
; System I/O
;
; Output Strobes
;
wr_rs_rx .set	0000h		; Write to reset AD6620
wr_out0	.set	2000h		; Write to spare LVDS OUT0
wr_out1	.set	4000h		; Write to spare LVDS OUT1
wr_rx		.set	4000h		; Updated RSP write address to avoid boot conflict
wr_rd_fifo	.set	6000h		; Write strobe to force TLM FIFO read
wr_disc	.set	8000h		; Write to discrete output latch
wr_dog	.set	0A000h	; Strobe watchdog timer chip
wr_out	.set	0C000h	; Output write; can be jumpered to FIFO
wr_rsv	.set	0E000h	; Write reserved/spare
;
; Input Strobes
;
rd_rx_out	.set	0000h		; Read Rx FIFO word (output enable)
clk_rx_out	.set	2000h		; Read strobe to clock next word from FIFO
rd_rx		.set	4000h		; Read AD6620 RSP registers
rd_out2	.set	6000h		; Strobe differential driver 30
rd_disc	.set	8000h		; Read discrete inputs
rs_rx_fifo	.set	0A000h	; Rx FIFO reset strobe
rs_fifo	.set	0C000h	; TLM FIFO reset strobe
rd_rsv	.set	0E000h	; Read address reserved for boot operation 
;
; Software Wait State Register (SWWSR) bit shifts
;
; Number of bits to shift to get to the base of a 3-bit wait 
; state definition.  These set the number of extra cycles to add 
; to a Program Space (PS), Data Space (DS), or I/O Space (IS) 
; access.  PS and DS are split.
;
swwsr_ps0	.set	0	; 0000-7FFFh Program
swwsr_ps1	.set	3	; 8000-FFFFh Program
swwsr_ds0	.set	6	; 0000-7FFFh Data
swwsr_ds1	.set	9	; 8000-FFFFh Data
swwsr_is	.set	12	; 0000-FFFFh I/O

; Example to set wait states
;	ldm		SWWSR, A
;	xor		#7, #swwsr_is, A ; (A xor 0b111<<Nset) to zero bits of set Nset
;	or		#0, #swwsr_is, A ; (A or Nwait<<Nset) to set Nwait to Nset
;	stlm	A, SWWSR
;
; Internal timer bit and timing definitions
;
ntss	.set	16		; TSS (timer stop) bit in TCR
ntddr	.set	0		; Timer prescaler load value ("divide by 1")
						; See timer value calculations below
nload	.set	32		; TRB (timer reload bit) in TCR
nprd	.set	2399	; Minor frame test (60 us / 25 ns)/(ntddr+1)-1
nwait	.set	1599	; (40 us / 25 ns)/(ntddr+1)-1

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

;
; AD6620 RSP register offsets
; Add to rd_rx/wr_rx to build final AD6620 External Interface Register Address
;
dr0	.set	0			; Data register 0, D[7:0]
dr1	.set	1			; Data register 1, D[15:8]
dr2	.set	2			; Data register 2, D[23:16]
dr3	.set	3			; Data register 3, D[31:24]
dr4	.set	4			; Data register 4, D[35:32]
rsv	.set	5			; Reserved
lar	.set	6			; Low address register A[7:0]
amr	.set	7			; Address mode register
					; 7: Write increment
					; 6: Read increment
					; 5-2: Reserved
					; 1-0: A[9:8]

;
; Discrete input bits at 8000h
;
trm_28	.set	0001h		; Terminal input (hardware EEPROM WR enable)
test_28	.set	0002h		; Test input
;
; Character constants
;
CR      .set    0Dh 
LF      .set    0Ah 
CRLF    .set    0D0Ah		; CR, LF as 1 word 
ESC     .set    1Bh 

;
; Scratchpad RAM addresses
; 
;state:	.set	60h		; Major frame interrupt routine state
;
; Constants
;
iq_len		.set	63		; N+1 words before I/Q off, LSB on
acq_seq_len .set 	32767   ; N+1 words to hold acq_seq high
seq_len		.set	65535	; Total N+1 words per trigger

;
; Discrete Outputs (at wr_disc)
;
par_tm_en	.set	1	; Parallel telemetry enable (active low)
lsb_sel		.set	2	; LSB/I_Q select, low for I_Q
acq_seq_rdy	.set	4 	; slave ready bit (output)
acq_ant_1	.set	8	; antenna 1 enable
acq_ant_2	.set	16	; antenna 2 enable
acq_test5	.set	32
acq_test6	.set	64
acq_seq_out	.set	128	; ACQ_SEQ output bit
;
; Discrete Inputs (at rd_disc)
;
disc_0		.set	1	; Same as trm_28 at monitor level
acq_seq_in	.set	2	; Dartmouth slave ACQ_SEQ input
tlm_ffo		.set	4	; Telemetry FIFO full flag
tlm_efo		.set	8	; Telemetry FIFO empty flag
tlm_hfo		.set	16	; Telemetry FIFO half-full flag
rx_ffo		.set	32	; Rx FIFO full flag
rx_efo		.set	64	; Rx FIFO empty flag
rx_hfo		.set	128	; Rx FIFO half-full flag

; Time-Division Multiplexed Serial Port Control Register bit definitions

tspc_tdm	.set	1		; TDM mode
tspc_dlb	.set	2		; digital loopback
tspc_fo		.set	4		; format
tspc_fsm	.set	8		; frame sync mode
tspc_mcm	.set	16		; clock mode
tspc_txm	.set	32		; transmit mode
tspc_nXrst	.set	64		; transmit reset
tspc_nRrst	.set	128		; receive reset
tspc_in0	.set	256		; binary state of receive clock line (r/o)
tspc_in1	.set	512		; binary state of transmit clock line (r/o)
tspc_Rrdy	.set	1024	; receive ready (r/o)
tspc_Xrdy	.set	2048	; transmit ready (r/o)
tspc_XSRfull .set	4096	; Transmit Shift Register full (r/o)
tspc_RSRfull .set	8192	; Receive Shift Register full (r/o)
tspc_Soft	.set	16384	; HLL debugging clock behavior bit
tspc_Free	.set	32768	; HLL debugging clock behavior bit

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


