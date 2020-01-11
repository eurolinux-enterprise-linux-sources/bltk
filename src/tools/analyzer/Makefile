
CFLAGS		= -Wall -pedantic -std=c99 -g -O2
#LDFLAGS	= -L/usr/X11R6/lib -lX11

BIN		= ../../bin

FILES		= bltk_calc

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		=

TARGETS		= $(BIN)/bltk_calc

SHFILES		= bltk_get_stat bltk_report bltk_report_table bltk_report_check \
			bltk_plot bltk_get_hd_rpm \
			bltk_report_compress bltk_report_uncompress
SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)


all : $(BIN) $(SUBDIRS) $(TARGETS) $(SHTARGETS) FORCE

$(TARGETS) : ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

bltk_calc.o : $(HIDERS) bltk_calc.c

$(SHTARGETS) : $(SHFILES_SH)
	cp $(@:$(BIN)/%=%.sh) $@
	@chmod a+x $@

$(BIN) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi

clean :
	@$(RM) $(TARGETS) *.o $(SHTARGETS) *~

FORCE :

