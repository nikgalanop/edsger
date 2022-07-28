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

edsger$(EXE): Ast.cmo Utilities.cmo Parser.cmo Lexer.cmo Main.cmo
	$(OCAMLC) $(OCAMLC_FLAGS) -o $@ $^

Lexer.ml: Lexer.mll
	ocamllex -o $@ $<

Parser.ml Parser.mli: Ast.cmi Parser.mly 
	menhir -v Parser.mly

.PHONY: clean distclean default

-include .depend

depend: Lexer.ml Lexer.mli Parser.ml Parser.mli Main.ml Utilities.mli Utilities.ml Ast.ml
	$(OCAMLDEP) $^ > .depend

clean:
	$(RM) Lexer.ml Parser.ml Parser.mli *.automaton *.conflicts *.cmo *.cmi *~

distclean: clean
	$(RM) edsger$(EXE) .depend