
TOOLS_SUBDIRS	= tools

WL_SUBDIRS	= wl_reader wl_developer wl_office wl_game wl_player

SUBDIRS		= $(TOOLS_SUBDIRS) $(WL_SUBDIRS)

CMDS		= bltk bltk_report bltk_report_table bltk_plot \
			bltk_report_compress bltk_report_uncompress

all : pre-install
	@for dir in $(SUBDIRS); \
	do \
		if [ ! -d $$dir ]; then continue; fi; \
		$(MAKE) -C $$dir $@; \
		if [ $$? != 0 ]; then exit 1; fi; \
	done
	@touch .bltk

install i : pre-install
	bin/bltk_install -i

install-developer i-d : pre-install
	$(MAKE) -C wl_developer install

install-office i-o : pre-install
	$(MAKE) -C wl_office install

install-game i-g : pre-install
	$(MAKE) -C wl_game install

install-player i-p: pre-install
	$(MAKE) -C wl_player install

install-player-src i-p-s : pre-install
	$(MAKE) -C wl_player install-src

install-player-bin i-p-b : pre-install
	$(MAKE) -C wl_player install-bin

install-player-loc i-p-l : pre-install
	$(MAKE) -C wl_player install-loc

uninstall u : FORCE
	bin/bltk_install -u

uninstall-developer u-d : FORCE
	$(MAKE) -C wl_developer uninstall

uninstall-office u-o : FORCE
	$(MAKE) -C wl_office uninstall

uninstall-game u-g: FORCE
	$(MAKE) -C wl_game uninstall

uninstall-player u-p : FORCE
	$(MAKE) -C wl_player uninstall

check c : FORCE
	bin/bltk_check

check-idle c-i : FORCE
	bin/bltk_check -I

check-reader c-r : FORCE
	bin/bltk_check -R

check-developer c-d : FORCE
	bin/bltk_check -D

check-office c-o : FORCE
	bin/bltk_check -O

check-game c-g : FORCE
	bin/bltk_check -G

check-player c-p : FORCE
	bin/bltk_check -P

clean : FORCE
	@for dir in $(SUBDIRS); \
	do \
		if [ ! -d $$dir ]; then continue; fi; \
		$(MAKE) -C $$dir $@; \
		if [ $$? != 0 ]; then exit 1; fi; \
	done
	@$(RM) $(CMDS)
	@$(RM) -r bin lib check.results results*
	@$(RM) *~ last_cmd last_results history
	@$(RM) .bltk install.log uninstall.log .plot_history

su : pre-install
	$(MAKE) -C tools/sudo install
	@touch .bltk

_lazy : FORCE
	@for f in $(CMDS); \
	do \
		$(RM) $$f; ln -s bin/$$f $$f; \
	done

_DIRS : FORCE
	@mkdir -p -m 0777 bin lib tmp extern

pre-install : _DIRS _lazy

CLEAN C : clean FORCE
	@$(RM) -r extern tmp

extern e : FORCE
	ln -s $(HOME)/extern extern

FORCE :
