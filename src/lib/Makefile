CC=gcc
AR=ar
CCFLAGS= -Wall -Werror -c
ARFLAGS= -cvq
default:
	$(CC) $(CCFLAGS) *.c
	$(AR) $(ARFLAGS) edsgerlib.a *.o
	rm *.o
