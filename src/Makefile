LIBPATH=./lib

.PHONY: compiler library

default: compiler library

compiler:
	dune build

library:
	make -C $(LIBPATH)

clean:
	make -C $(LIBPATH) clean;
	$(RM) *.{ll, s}

distclean: clean
	dune clean;
	make -C $(LIBPATH) distclean;
	$(RM) *.out *.opam
