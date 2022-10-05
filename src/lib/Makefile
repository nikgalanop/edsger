CC=clang
CFLAGS=-Wall -Werror -c
LIB=edsgerlib.a
default:
	$(CC) $(CFLAGS) *.c
	$(AR) $(ARFLAGS) $(LIB) *.o
	$(RM) *.o
