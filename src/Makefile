BUILDPATH=./_build/default/bin/
LIBPATH=./lib
LIB=$(LIBPATH)/edsgerlib.a

.PHONY: compiler library

default: compiler library

compiler:
	dune build;	

library:
	make -C $(LIBPATH);

distclean:
	dune clean;
	make -C $(LIBPATH) distclean
