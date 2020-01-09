
CFLAGS		= -Wall -pedantic -std=c99 -g -O2 -I../include
LDFLAGS		= -L/usr/X11R6/lib64 -L/usr/X11R6/lib -lX11 -lxse -L../lib

BIN		= bin

PROG		= bltk_wl_developer_xse
TARGET		= $(BIN)/$(PROG)
OFILES		= ${PROG:=.o}

HIDERS		= ../include/bltk.h ../include/xse.h

SHFILES		= bltk_wl_developer_install bltk_wl_developer bltk_wl_developer_spy

SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)

EXTERN_DEPS	=  $(HIDERS) ../lib/libxse.so


all : $(BIN) $(SUBDIRS) $(TARGET) $(SHTARGETS) FORCE

install :
	@bin/bltk_wl_developer_install $@

uninstall :
	@bin/bltk_wl_developer_install $@

check : FORCE
	../bin/bltk_check -D

i : install
u : uninstall
c : check


$(TARGET) : $(EXTERN_DEPS) ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

$(PROG).o : $(HIDERS) $(PROG).c


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
