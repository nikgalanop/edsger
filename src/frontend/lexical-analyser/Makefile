# https://courses.softlab.ntua.gr/compilers/2011a/examples/minibasic/OCaml/lexer/Makefile
# OS type: Linux/Win DJGPP
ifdef OS
   EXE=.exe
else
   EXE=
endif

OCAMLC_FLAGS=-g
OCAMLC=ocamlc

lexer: lexer.ml
	$(OCAMLC) -o $@ $<

%.cmo: %.ml %.mli
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

%.cmi: %.mli
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

%.cmo %.cmi: %.ml
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

lexer.ml: lexer.mll
	ocamllex -o $@ $<

.PHONY: clean distclean

clean:
	$(RM) lexer.ml *.cmo *.cmi *~

distclean: clean
	$(RM) lexer$(EXE)