
CFLAGS		= -Wall -pedantic -std=c99 -g -O2
#LDFLAGS	= -L/usr/X11R6/lib -lX11

BIN		= ../../bin

FILES		= bltk_time

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		=

TARGETS		= $(BIN)/bltk_time

SHFILES		=
SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)


all : $(BIN) $(SUBDIRS) $(TARGETS) $(SHTARGETS) FORCE

$(TARGETS) : ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

bltk_time.o : $(HIDERS) bltk_time.c

$(SHTARGETS) : $(SHFILES_SH)
	cp $(@:$(BIN)/%=%.sh) $@
	@chmod a+x $@

$(BIN) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi

clean :
	@$(RM) $(TARGETS) *.o $(SHTARGETS) *~

FORCE :
