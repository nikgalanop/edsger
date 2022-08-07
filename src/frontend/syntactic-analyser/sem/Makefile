.PHONY: clean distclean pack

# OS type: Linux/Win DJGPP
ifdef OS
   EXE=.exe
else
   EXE=
endif

MLFILES=Hashcons.ml Identifier.ml Error.ml Types.ml Symbol.ml \
  Parser.ml Utilities.ml Ast.ml Semantic.ml Lexer.ml Main.ml
MLIFILES=Hashcons.mli Identifier.mli Error.mli Types.mli Symbol.mli \
  Parser.mli Ast.mli Utilities.mli Lexer.mli
CMOFILES=$(patsubst %.ml,%.cmo,$(MLFILES))
CMIFILES=$(patsubst %.ml,%.cmi,$(MLFILES))
CMXFILES=$(patsubst %.ml,%.cmx,$(MLFILES))
OBJFILES=$(patsubst %.ml,%.o,$(MLFILES))
PARSERFILES=Parser.ml Parser.mli Parser.output Lexer.ml

OCAMLC_FLAGS=-g
OCAMLOPT_FLAGS=
OCAMLC=ocamlc $(OCAMLC_FLAGS)
OCAMLOPT=ocamlopt $(OCAMLOPT_FLAGS)
OCAMLDEP=ocamldep
INCLUDES=

edsger$(EXE): $(CMOFILES)
	$(OCAMLC) -o $@ $^

%.cmi: %.mli
	$(OCAMLC) -c $<

%.cmo: %.ml %.mli 
	$(OCAMLC) -c $<

%.cmx: %.ml
	$(OCAMLOPT) -c $<

%.cmo %.cmi: %.ml
	$(OCAMLC) -c $<

Parser.ml Parser.mli: Ast.cmi Parser.mly
	menhir -v --infer Parser.mly

Lexer.ml: Lexer.mll
	ocamllex Lexer.mll

.PHONY: clean distclean depend

-include .depend

depend: $(MLFILES) $(MLIFILES)
	$(OCAMLDEP) $^ > .depend

clean:
	$(RM) $(CMXFILES) $(CMOFILES) $(CMIFILES) $(OBJFILES) $(EXEFILES) \
           $(patsubst %,%.cm?,$(EXEFILES)) $(PARSERFILES) *~

distclean: clean
	$(RM) $(EXEFILE) edsger$(EXE) .depend
