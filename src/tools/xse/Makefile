
CFLAGS		= -Wall -pedantic -std=c99 -g -O2 -I ../../include -fPIC
LDFLAGS		= -L/usr/X11R6/lib64 -L/usr/X11R6/lib -lX11

LIB		= ../../lib

LIBNAME		= libxse.so
TARGET		= $(LIB)/$(LIBNAME)
FILES		= xse
OFILES		= ${FILES:=.o}
HIDERS		= ../../include/xse.h

all : $(LIB) $(TARGET) FORCE

$(TARGET) : ${OFILES}
	$(CC) -shared $(CFLAGS) $(LDFLAGS) -o $@ ${OFILES}

xse.o : $(HIDERS) xse.c

$(LIB) : FORCE
	@if [ ! -d $@ ]; then mkdir -p -m 0777 $@; fi

xse.o : $(HIDERS) xse.c

clean :
	@$(RM) $(TARGET) *.o *~

FORCE :
