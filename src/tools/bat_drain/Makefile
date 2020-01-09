
CFLAGS		= -Wall -pedantic -std=c99 -g -O2
#LDFLAGS	= -L/usr/X11R6/lib -lX11

BIN		= ../../bin

FILES		=

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		=

TARGETS		=

SHFILES		= bat_drain bat_drain_table
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
	@$(RM) -r $(TARGETS) *.o $(SHTARGETS) *~ results* last_cmd last_results

FORCE :
