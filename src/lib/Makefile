CC=clang
AR=ar
CCFLAGS=-Wall -Werror -c
ARFLAGS=-cvq
LIB=edsgerlib.a
default:
	$(RM) $(LIB)
	$(CC) $(CCFLAGS) *.c
	$(AR) $(ARFLAGS) $(LIB) *.o
	$(RM) *.o
