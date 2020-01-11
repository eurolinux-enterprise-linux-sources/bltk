
CFLAGS		= -Wall -pedantic -std=c99 -g -O2 -I../include
LDFLAGS		= -L/usr/X11R6/lib64 -L/usr/X11R6/lib -lX11 -lxse -L ../lib

BIN		= bin

TARGETS		= $(BIN)/bltk_wl_reader_xse

FILES		= bltk_wl_reader_xse

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		= ../include/bltk.h ../include/xse.h

SHFILES		= bltk_wl_reader_install bltk_wl_reader
SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)

EXTERN_DEPS	= $(HIDERS) ../lib/libxse.so


all : $(BIN) $(SUBDIRS) $(TARGETS) $(SHTARGETS) FORCE

install :
	@bin/bltk_wl_reader_install $@

uninstall :
	@bin/bltk_wl_reader_install $@

check : FORCE
	../bin/bltk_check -R

i : install
u : uninstall
c : check

$(TARGETS) : $(EXTERN_DEPS) ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

bltk_wl_reader_xse.o : $(HIDERS) bltk_wl_reader_xse.c

$(SHTARGETS) : $(SHFILES_SH)
	cp $(@:$(BIN)/%=%.sh) $@
	@chmod a+x $@

$(BIN) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi

clean :
	@$(RM) $(TARGET) *.o $(SHTARGETS) *~
	@$(RM) winid.tmp user_delay.tmp fail score env.log work_out.log
	@$(RM) install.log uninstall.log
	@$(RM) -r $(BIN) check.results results

FORCE :
