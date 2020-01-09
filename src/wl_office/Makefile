
CFLAGS		= -Wall -pedantic -std=c99 -g -O2 -I../include
LDFLAGS		= -L/usr/X11R6/lib64 -L/usr/X11R6/lib -lX11 -lxse -L../lib

BIN		= bin

PROG		= bltk_wl_office_xse
TARGET		= $(BIN)/$(PROG)
OFILES		= ${PROG:=.o}

HIDERS		= ../include/bltk.h ../include/xse.h

SHFILES		= bltk_wl_office_install bltk_wl_office bltk_wl_office_run_app install_linux

SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)

DATAFILES	= scen_install 
DATATARGETS	= $(DATAFILES:%=$(BIN)/%)

EXTERN_DEPS	= $(HIDERS) ../lib/libxse.so


all : $(BIN) $(SUBDIRS) $(TARGET) $(TARGET1) $(TARGET2) $(SHTARGETS) $(DATATARGETS)

install :
	@bin/bltk_wl_office_install $@

uninstall :
	@bin/bltk_wl_office_install $@

check : FORCE
	../bin/bltk_check -O

i : install
u : uninstall
c : check

$(TARGET) : $(EXTERN_DEPS) ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

$(PROG).o : $(HIDERS) $(PROG).c

$(SHTARGETS) : $(SHFILES_SH)
	cp $(@:$(BIN)/%=%.sh) $@
	@chmod a+x $@

$(DATATARGETS) : $(DATAFILES)
	cp $(@:$(BIN)/%=%) $@
	@chmod a+rw $@

$(BIN) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi

clean :
	@$(RM) $(TARGET) *.o $(SHTARGETS) *~
	@$(RM) winid.tmp user_delay.tmp fail score env.log work_out.log
	@$(RM) install.log uninstall.log
	@$(RM) -r $(BIN) check.results results
	@$(RM) OOCALC_FILE.ods OODRAW_FILE.odg OOWRITER_FILE.odt

FORCE :
