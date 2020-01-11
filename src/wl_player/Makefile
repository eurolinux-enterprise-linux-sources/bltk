
CFLAGS		= -Wall -pedantic -std=c99 -g -O2
LDFLAGS		= -L/usr/X11R6/lib64 -L/usr/X11R6/lib -lX11

BIN		= bin

TARGETS		=

FILES		=

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		=

SHFILES		= bltk_wl_player_install bltk_wl_player bltk_wl_player_make_binary
SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)


all : $(BIN) $(SUBDIRS) $(TARGETS) $(SHTARGETS) FORCE

install :
	@bin/bltk_wl_player_install $@

install-src :
	@bin/bltk_wl_player_install $@

install-bin :
	@bin/bltk_wl_player_install $@

install-loc :
	@bin/bltk_wl_player_install $@

uninstall :
	@bin/bltk_wl_player_install $@

binary :
	@bin/bltk_wl_player_make_binary

check : FORCE
	../bin/bltk_check -P

i : install
i-s : install-src
i-b : install-bin
i-l : install-loc
u : uninstall
c : check

$(TARGETS) : ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

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
