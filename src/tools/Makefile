
SUBDIRS = xse bltk sudo get_realpath type_command analyzer time bat_drain

all : FORCE
	@for dir in $(SUBDIRS); \
	do \
		$(MAKE) -C $$dir $@; \
		if [ $$? != 0 ]; then exit 1; fi; \
	done

clean : FORCE
	@for dir in $(SUBDIRS); \
	do \
		$(MAKE) -C $$dir $@; \
		if [ $$? != 0 ]; then exit 1; fi; \
	done

install :

uninstall :

su sudo : FORCE
	$(MAKE) -C sudo

FORCE :

