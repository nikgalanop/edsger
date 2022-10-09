CC=clang
CFLAGS=-Wall -Werror -c
LIB=edsgerlib.a
LIBPATH=./lib-implementation

default:
	$(CC) $(CFLAGS) $(LIBPATH)/*.c
	$(AR) $(ARFLAGS) $(LIB) *.o
	$(RM) *.{o}

clean:
	$(RM) *.o

distclean: 
	$(RM) $(LIB) *.o
