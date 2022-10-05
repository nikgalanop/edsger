### Tools:
- This compiler is written in OCaml.
- We use both dune and Makefile as our build system.
- For the lexer, it uses ocamllex.
- For the parser, it uses Menhir.
- We used a different symbol table for semantic analysis and IR Generation. Both of these symbol tables are heavily
inspired by the code that is provided [here](https://courses.softlab.ntua.gr/compilers/2010a/bonus-ocaml-1.0.tgz)
- We used LLVM and the LLVM bindings for OCaml, to produce LLVM IR from the AST that we generate.
- It calls llc and clang to convert the produced LLVM IR to assembly or executable form.
- We use ar and clang to create the prepackaged static library.

### Filenames:
- The input file to the compiler, must have the extension `.eds`.
- An "included" file must have either the extension `.eds` or `.h`.

### Macros
- As stated in the specification, the only macro instruction allowed is `#include`. If a 'cyclical' include sequence
is provided, then the compiler warns the user about this, omits the macro that caused the cycle and proceeds with
compiling the rest of the program.

### Library Functions
- The prepackaged static library of edsger, is written in C. (`path/to/edsger/src/lib`)
- The header files for this prepackaged library are provided in `path/to/edsger/misc/test-programs/lib-headers`.
- When compiling a program, the necessary library headers as well as the archive file of the static library must be present
in the same directory as the source file.
- `readChar ()` does not "read" whitespaces. It is implemented by calling `scanf(" %c", &ref)`.
- `readString (int size, char * s)` reads at most `size - 1` characters from `stdin` and null-terminates the string properly,
by placing a null byte as the `size`-th character in the provided buffer. The function reads from `stdin` as long as it has 
not reached `EOF` or it not read the newline char `'\n'`. The `'\n'` is not included in the returned string.

### Overloading:
- We allow function overloading.
- We do not allow the declaration of two functions with the same name and equivalent parameter lists. Two parameters 
are equivalent if they have the same type. (We do not care about the pass method) Two parameter lists are equivalent 
if their contents are equivalent.
- We use name mangling in both the symbol tables (Semantic analysis and IR Generation) and in the LLVM IR representation.
For the LLVM IR representation, the name mangling convention is the following:

```
<mangled> ::= <original_name>_<parameters_str>_counter
<parameters_str> ::= <parameter_str>* 
```

The original name is the name of the function in the provided `.eds` file (as well as the included `.eds` or `.h` files).
The parameter string is created only from the explicit parameters of the function (meaning that we do not care about any 
parameters that it accesses outside of its scope, that are not global, when the function is nested). We traverse the 
explicit parameters in order and create a string for each parameter with the following correspondance:

```
<parameter_str> ::= <primitive_str> <pointer_str>
<primitive_str> ::= 'i' | 'd' | 'c' | 'b' // Corresponds to the types 'int', 'double', 'char', 'bool'
<pointer_str> ::= ([1-9][0-9]* | ε) // Corresponds to the "dimension" of the pointer. 
```

We also use a counter in case that two functions have the same name and explicit parameters. This can happen in the case 
of function shadowing (a nested function shadows a function with the same name and parameters from an outer scope), or 
when two functions have the same name and parameters but are also nested inside different functions.

### Function Declarations
- A declaration of a function and a definition of the same function do not have to agree in the name of the parameters.
(C-like function declaration)
- A declaration of a function cannot be placed after the definition of the same function.

### Nested Functions
- In edsger, the programmer can nest functions. The nested functions can access variables from the outer scopes in which 
they are nested into, as expected. This is implemented via lambda lifting.

### Type Casting:
- We allow every possible type casting between arithmetic types.
- We only allow a pointer to be cast to an int.
- We do not allow any arithmetic value to be cast into a pointer.
- We allow casting between pointer types freely.

### Labels:
- We do not allow two labels in the same function to have the same name.
- We only allow jumps to a label if the "jump" command is nested in the body of the labeled for-loop that is the jump 
destination.

### Static Array Declarations:
- When defining an array statically, the size of the array must be a **positive** constant integer expression. A constant 
integer expression is a constant expression of type int, defined as stated below:
    > A constant integer expression can be:
    > 1. a constant int
    > 2. the result of the operations '+', '-', '*', '/', '%'
    > between two <ins>constant integer expressions</ins>
    > 3. a constant double, casted to an int
    > 4. the result of the operations '+', '-', '*', '/', '%'
    > between two constant doubles, casted to an int.
- Global arrays are initialized to contain zeros. This is not guaranteed when declaring a local static array.