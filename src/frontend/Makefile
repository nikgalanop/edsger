.PHONY: default clean distclean

# OS type: Linux/Win DJGPP
ifdef OS
   EXE=.exe
else
   EXE=
endif

OCAMLBUILD_FLAGS=-use-ocamlfind -use-menhir -r -Is
INCLUDES=syntactic-analyser,semantic-analyser,semantic-analyser/symbol-table,utilities,lexical-analyser,ast-creator
OCAMLBUILD=ocamlbuild $(OCAMLBUILD_FLAGS) $(INCLUDES)

edsger$(EXE):
	$(OCAMLBUILD) "Main.native"; 
	rm Main.native;
	mv ./_build/Main.native ./edsger$(EXE);
	$(RM) -r _build

clean:
	$(RM) -r _build

distclean: clean
	$(RM) edsger$(EXE)