.PHONY: default clean distclean

# OS type: Linux/Win DJGPP
ifdef OS
   EXE=.exe
else
   EXE=
endif

# Frontend Directories
LEXD=lexical-analyser
SYND=syntactic-analyser
ASTD=ast-creator
SEMD=semantic-analyser,semantic-analyser/symbol-table
UTLD=utilities

OCAMLBUILD_FLAGS=-use-ocamlfind -use-menhir -r -Is
INCLUDES=$(LEXD),$(SYND),$(ASTD),$(SEMD),$(UTLD)
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