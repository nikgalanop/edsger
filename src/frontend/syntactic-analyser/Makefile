# https://courses.softlab.ntua.gr/compilers/2011a/examples/minibasic/OCaml/lexer/Makefile
# OS type: Linux/Win DJGPP
ifdef OS
   EXE=.exe
else
   EXE=
endif

OCAMLC_FLAGS=-g
OCAMLC=ocamlc
OCAMLDEP=ocamldep

%.cmo: %.ml %.mli
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

%.cmi: %.mli
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

%.cmo %.cmi: %.ml
	$(OCAMLC) $(OCAMLC_FLAGS) -c $<

Lexer.ml: Lexer.mll
	ocamllex -o $@ $<

Parser.ml Parser.mli: Parser.mly
	ocamlyacc -v Parser.mly

.PHONY: clean distclean

-include .depend

depend: Lexer.ml Lexer.mli Parser.ml Parser.mli Main.ml
	$(OCAMLDEP) $^ > .depend

clean:
	$(RM) lexer.ml *.cmo *.cmi *~

distclean: clean
	$(RM) lexer$(EXE)