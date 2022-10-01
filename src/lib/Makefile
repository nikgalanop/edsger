CC=clang
CCFLAGS=-Wall -Werror -c
LIB=edsgerlib.a
default:
	$(RM) $(LIB)
	$(CC) $(CCFLAGS) *.c
	$(AR) $(ARFLAGS) $(LIB) *.o
	$(RM) *.o
