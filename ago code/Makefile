MAINSRC ?= ago_v1.0.asm
CFPREFIX ?= twostage

ASMFLAG = -v542
LNKFLAG = -w -a -r

CGTDIR = /cygdrive/c/TI54xCGT/bin
#CGTDIR = /cygdrive/c/ti/ccsv5/tools/compiler/c5400/bin

BASESRC = int_table.asm bl549.asm ad6620.asm tablemax.asm
FUNCSRC = $(BASESRC) Cbrev32.asm c512.asm log_10.asm hannwin.asm sercook.asm cfft_32.asm dpsm.asm scale.asm
TABLES = hann_q15.tab

OBJECTS = $(MAINSRC:.asm=.obj) $(FUNCSRC:.asm=.obj) $(TABLES:.tab=.obj)
LSTS = $(FUNCSRC:.asm=.lst) $(MAINSRC:.asm=.lst)
ABSS = $(FUNCSRC:.asm=.abs) $(MAINSRC:.asm=.abs)

OUTMAP = $(MAINSRC:.asm=-link.map)
HEXMAP = $(MAINSRC:.asm=-hex.map)

OUTFILE = $(MAINSRC:.asm=.out)
HEXFILE = $(MAINSRC:.asm=.hex)

.SUFFIXES: .asm .obj .abs .lst .hex .out .tab

all: $(HEXFILE) $(LSTS)

$(HEXFILE): $(OUTFILE) toolhex.cmd
	$(CGTDIR)/hex500.exe $(HEXFLAG) $(CFPREFIX)hex.cmd -map $(HEXMAP) -o $(HEXFILE) -i $(OUTFILE)

.abs.lst: $(ABSS)
	$(CGTDIR)/asm500.exe $(ASMFLAG) -x -a $<

.obj.abs: $(OUTFILE)
	$(CGTDIR)/abs500.exe $(OUTFILE)
	
$(OUTFILE): $(OBJECTS) toollink.cmd rx-dsp.h int_table.h ad6620.asm
	$(CGTDIR)/lnk500.exe $(LNKFLAG) $(CFPREFIX)link.cmd -m $(OUTMAP) -o $(OUTFILE) $(OBJECTS)

.tab.obj:
	$(CGTDIR)/asm500.exe $(ASMFLAG) $< $@

.asm.obj:
	$(CGTDIR)/asm500.exe $(ASMFLAG) $< $@

clean:
	rm -f $(OBJECTS) $(LSTS) $(ABSS) $(OUTFILE) $(HEXFILE) $(OUTMAP) $(HEXMAP)


