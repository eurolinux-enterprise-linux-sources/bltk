
CFLAGS		= -Wall -pedantic -std=c99 -g -O2
#LDFLAGS	= -L/usr/X11R6/lib -lX11

BIN		= ../../bin

FILES		= bltk_sudo

OFILES		= ${FILES:=.o}
CFILES		= ${FILES:=.c}

HIDERS		=

TARGETS		= $(BIN)/bltk_sudo

SHFILES		=
SHFILES_SH	= ${SHFILES:=.sh}
SHTARGETS	= $(SHFILES:%=$(BIN)/%)


all : $(BIN) $(SUBDIRS) $(TARGETS) $(SHTARGETS) FORCE

$(TARGETS) : ${OFILES}
	$(CC) $(OFILES) $(LDFLAGS) -o $@

bltk_sudo.o : $(HIDERS) bltk_sudo.c

$(SHTARGETS) : $(SHFILES_SH)
	cp $(@:$(BIN)/%=%.sh) $@
	@chmod a+x $@

$(BIN) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi


install : FORCE
	@echo Root password is required
	@su root -c "chown root:root $(TARGETS); chmod +s $(TARGETS)"

clean :
	@$(RM) $(TARGETS) *.o $(SHTARGETS) *~

FORCE :
