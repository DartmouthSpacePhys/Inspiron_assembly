MAINSRC ?= sond_v1.3.asm
CFPREFIX ?= sond

ASMFLAG = -v542
LNKFLAG = -w -a -r
HEXFLAG = -memwidth 8 -romwidth 8 -boot -bootorg 0x0000

CGTDIR = /cygdrive/c/TI54xCGT/bin

BASESRC = ad6620_SS.asm bl549.asm int_table.asm sercook.asm
FUNCSRC = $(BASESRC)

OBJECTS = $(MAINSRC:.asm=.obj) $(FUNCSRC:.asm=.obj) $(TABLES:.tab=.obj)
LSTS = $(FUNCSRC:.asm=.lst) $(MAINSRC:.asm=.lst)
ABSS = $(FUNCSRC:.asm=.abs) $(MAINSRC:.asm=.abs)

OUTMAP = $(MAINSRC:.asm=-link.map)
HEXMAP = $(MAINSRC:.asm=-hex.map)

OUTFILE = $(MAINSRC:.asm=.out)
HEXFILE = $(MAINSRC:.asm=.hex)

USRC	?= sond_v0.1_u
USRCEX	= $(USRC)0.asm $(USRC)1.asm $(USRC)2.asm
UOUTFILES = $(USRCEX:.asm=.out)
UHEXFILES = $(USRCEX:.asm=.hex)
UCOBJECTS = $(USRCEX:.asm=.obj)
UFOBJECTS = $(FUNCSRC:.asm=.obj)

.SUFFIXES: .asm .obj .abs .lst .hex .out .tab

all: $(HEXFILE) $(LSTS)

units: $(UHEXFILES)

$(HEXFILE): $(OUTFILE) $(CFPREFIX)hex.cmd
	$(CGTDIR)/hex500.exe $(HEXFLAG) $(CFPREFIX)hex.cmd -map $(HEXMAP) -o $(HEXFILE) -i $(OUTFILE)

.abs.lst: $(ABSS)
	$(CGTDIR)/asm500.exe $(ASMFLAG) -x -a $<

.obj.abs: $(OUTFILE)
	$(CGTDIR)/abs500.exe $(OUTFILE)
	
$(OUTFILE): $(OBJECTS) $(CFPREFIX)link.cmd rx-dsp.h
	$(CGTDIR)/lnk500.exe $(LNKFLAG) $(CFPREFIX)link.cmd -m $(OUTMAP) -o $(OUTFILE) $(OBJECTS)

.tab.obj:
	$(CGTDIR)/asm500.exe $(ASMFLAG) $< $@

.asm.obj:
	$(CGTDIR)/asm500.exe $(ASMFLAG) $< $@

clean:
	rm -f $(OBJECTS) $(UCOBJECTS) $(UFOBJECTS) $(UOUTFILES) $(UHEXFILES) $(LSTS) $(ABSS) $(OUTFILE) $(HEXFILE) $(OUTMAP) $(HEXMAP)

tests: master_test.obj
	$(CGTDIR)/lnk500.exe -o master_test.out master_test.obj
#	$(CGTDIR)/lnk500.exe $(LNKFLAG) -o slave_test.out slave_test.obj
	$(CGTDIR)/hex500.exe $(HEXFLAG) -o master_test.hex -i master_test.out

#$(UOBJECTS): $(USRCEX) $(FUNCSRC)
#	$(CGTDIR)/asm500.exe $(ASMFLAG) $< $@	

#$(UOUTFILES): $(UCOBJECTS) $(UFOBJECTS)
#	$(CGTDIR)/lnk500.exe $(LNKFLAG) $(CFPREFIX)link.cmd -m $(OUTMAP) -o $@ $< $(UFOBJECTS)

#$(UHEXFILES): $(UOUTFILES)
#	$(CGTDIR)/hex500.exe $(HEXFLAG) $(CFPREFIX)hex.cmd -map $(HEXMAP) -o $@ -i $<
