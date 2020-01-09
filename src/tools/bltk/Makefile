
CFLAGS		= -Wall -pedantic -std=c99 -g -O2 -I../../include
#LDFLAGS	= -L/usr/X11R6/lib -lX11

BIN		= ../../bin

FILES		= main init file stat

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		= ../../include/bltk.h

TARGETS		= $(BIN)/bltk

SHFILES		= \
		bltk_hd_state bltk_save_sys_info bltk_get_info \
		bltk_get_ac_adapter bltk_get_bat bltk_get_cpustat \
		bltk_get_cpufreq bltk_get_cpuinfo bltk_get_cpustate \
		bltk_get_dmidecode bltk_get_hdparm \
		bltk_get_kernel_release bltk_get_meminfo \
		bltk_get_system_release bltk_get_xdpyinfo \
		bltk_get_lspci bltk_get_timer bltk_winid \
		bltk_display_state bltk_spy \
		bltk_wl_common bltk_check bltk_install \
		bltk_get_user_field

SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)


all : $(BIN) $(SUBDIRS) $(TARGETS) $(SHTARGETS) FORCE

$(TARGETS) : ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

main.o : $(HIDERS) main.c
init.o : $(HIDERS) init.c
file.o : $(HIDERS) file.c
stat.o : $(HIDERS) stat.c

$(SHTARGETS) : $(SHFILES_SH)
	cp $(@:$(BIN)/%=%.sh) $@
	@chmod a+x $@

$(BIN) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi

clean :
	@$(RM) $(TARGETS) *.o $(SHTARGETS) *~

FORCE :
