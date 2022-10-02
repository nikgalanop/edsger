CC=clang
CFLAGS=-Wall -Werror -c
LIB=edsgerlib.a
default:
	$(RM) $(LIB)
	$(CC) $(CFLAGS) *.c
	$(AR) $(ARFLAGS) $(LIB) *.o
	$(RM) *.o
