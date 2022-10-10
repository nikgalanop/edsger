CC=clang
CFLAGS=-Wall -Werror -c
LIB=edsgerlib.a
LIBPATH=./lib-implementation
STDIO=$(LIBPATH)/stdio
STDLIB=$(LIBPATH)/stdlib
STRING=$(LIBPATH)/string
MATH=$(LIBPATH)/math

default: stdio stdlib string math
	$(AR) $(ARFLAGS) $(LIB) *.o

stdio:
	$(CC) $(CFLAGS) $(STDIO)/*.c

stdlib:
	$(CC) $(CFLAGS) $(STDLIB)/*.c

string:
	$(CC) $(CFLAGS) $(STRING)/*.c

math:
	$(CC) $(CFLAGS) $(MATH)/*.c

clean:
	$(RM) *.o

distclean: 
	$(RM) $(LIB) *.o
