# Edsger Documentation

This is a summary of the design choices that we ([1](https://github.com/el18177), [2](https://github.com/nikgalanop))
reached upon, in this implementation of the edsger language. The specification of the said language can be found 
[here](https://courses.softlab.ntua.gr/compilers/2022a/edsger2022.pdf). You can find some example edsger programs 
in `path/to/edsger/src/testing` or equivalently [here](https://github.com/nikgalanop/edsger/tree/main/src/testing).

## Table Of Contents
<details> 
  <summary>Compiler Structure Details</summary>
  <ul>
      <li><a href="#tools">Tools</a></li>
      <li><a href="#installation-and-usage">Installation and Usage</a></li>
      <li><a href="#compiler-behaviour-and-options">Compiler Behaviour And Options</a></li>
      <li><a href="#filenames">Filenames</a></li>
      <li><a href="#directives">Directives</a></li>
      <li><a href="#library-functions">Library Functions</a></li>
   </ul>
</details>
<details>
  <summary>Language Feature Implementation Details</summary>
  <ul>
      <li><a href="#variable-types-and-constants">Variable Types And Constants</a></li>
      <li><a href="#function-declarations">Function Declarations</a></li>
      <li><a href="#function-overloading">Function Overloading</a></li>
      <li><a href="#nested-functions">Nested Functions</a></li>
      <li><a href="#local-variable-declarations">Local Variable Declarations</a></li>
      <li><a href="#static-array-declarations">Static Array Declarations</a></li>
      <li><a href="#dynamic-memory-allocation">Dynamic Memory Allocation</a></li>
      <li><a href="#erroneous-accesses">Erroneous Accesses</a></li>
      <li><a href="#labels">Labels</a></li>
      <li><a href="#type-casting">Type Casting</a></li>
   </ul>
</details>  
<details>
    <summary>Miscellaneous</summary>
  <ul>
      <li><a href="#grammar-conflicts">Grammar Conflicts</a></li>
      <li><a href="#order-of-evaluations">Order of Evaluations</a></li>
   </ul>
</details>

## Compiler Structure Details

### Tools
- This compiler is written in [OCaml](https://ocaml.org/).
- We use both [`dune`](https://dune.build/) and `GNU Make` as our build system.
- For the lexer, it uses `ocamllex`.
- For the parser, it uses [`Menhir`](http://gallium.inria.fr/~fpottier/menhir/).
- We used a different symbol table for semantic analysis and IR Generation. Both of these symbol tables are heavily
inspired by the code that is provided [here](https://courses.softlab.ntua.gr/compilers/2010a/bonus-ocaml-1.0.tgz)
- We used [LLVM](https://llvm.org/) and the [LLVM bindings](https://opam.ocaml.org/packages/llvm/) for OCaml, to produce 
LLVM IR from the AST that we generate.
- It calls `llc` and `clang` to convert the produced LLVM IR to x86_64 assembly or executable form.
- We use `ar` and `clang` to create the prepackaged static library.

#### System Requirements
The compiler has been built from source successfully in two different systems with the following configuration:
  |             Target               |  OCaml   |  opam   |  dune   |  GNU Make  |  ocamllex  |   Menhir   |   LLVM   |  LLVM Bindings  |      Clang       |
  | :------------------------------: | :------: | :-----: | :-----: | :--------: | :--------: | :--------: | :------: | :-------------: | :--------------: |
  |        Arch Linux, x86_64        |  4.14.0  |  2.1.3  |  3.5.0  |    4.3     |   4.14.0   |  20220210  |  14.0.6  |     14.0.6      |      14.0.6      |
  | Ubuntu 20.0.4 LTS @ WSL2, x86_64 |  4.14.0  |  2.1.0  |  3.4.1  |   4.2.1    |   4.14.0   |  20220210  |  10.0.0  |     12.0.1      |  10.0.0-4ubuntu1 |

### Installation and Usage
- Build from [source](https://github.com/nikgalanop/edsger/src). <br>
In order to build from source, just execute the Makefile
inside `path/to/edsger/src/` by writing `make` and executing it in your terminal. Both the compiler and the static library are 
made. The static library is located in `path/to/edsger/src/lib/`, the compiler executable is located in `/path/to/edsger/src/_build/default/bin/Main.exe`. It can either be copied from there and renamed or it can be executed via dune as following: `dune exec edsger filename.eds`. In order to provide compiler options, the user must add two dashes, when executing the compiler via dune: 
`dune exec -- edsger [options] filename.eds`

#### Note ⚠️ 
In both cases the user must `export EDS_LIB_DIR=/path/to/lib/` to their environment, either by adding it in `~/.bashrc` and 
restarting the terminal session or just exporting the variable via the terminal (the latter stores the variable only for the 
current terminal session).

### Compiler Behaviour And Options
- The standard usage of the compiler (no flags), reads from an input file `name.eds` and produces three files `name.ll`, `name.s`, 
`name.out`. The first two contain the LLVM IR and the x86_64 assembly accordingly. The `.out` file is the produced executable.
- There are four options that can be passed to the compiler:
  1. `-O`: when provided, enables the LLVM IR optimization. The optimization process consists of the following passes:
      `mem2reg`, `Instruction Combining`, `Reassociation`, `CFG Simplification`, `Global Value Numbering (GVN)`, `Aggressive DCE`.
      Regardless of the usage of this option, when our compiler calls `llc`, the `llc` optimization level is set to `-O2`, 
      meaning that the produced assembly code will always be optimized.
  2. `-i`: when provided, the compiler reads from `stdin` and outputs the produced LLVM IR to `stdout`. No input file should 
      be provided. No output file is produced.
  3. `-f`: when provided, the compiler reads from `stdin` and outputs the produced assembly to `stdout`. No input file should 
      be provided. No output file is produced.
  4. `-help` / `--help` : when provided, the compiler outputs a list of the available options, the ones that we are describing 
      above.
- This simple CLI is implemented with the usage of the `Arg` module.

### Filenames
- The input file to the compiler, must have the extension `.eds`.
- An "included" file must have either the extension `.eds` or `.h`.

### Directives
- As stated in the specification, the only directive allowed is `#include`. If a 'cyclical' include sequence is provided,
then the compiler warns the user about this, omits the directive that caused the cycle and proceeds with compiling the rest of the 
program. (The same happens in any case where a file is to be included twice.)
- The source file that is provided to the compiler is assumed to be "`include`d", meaning that if any descendant file, includes the
source file, the compiler handles the case as if the source file has been already included.
- When `file1.{h,eds}` includes `file2.{h,eds}` as following:`#include "/path/to/file2.{h,eds}"`, then the compiler checks if the 
file is present in `path_of_file_1/path/to/file2.{h,eds}`. This reposition happens recursively, meaning that if now `file2.{h,eds}` includes another file, eg. `#include /a/new/path/to/file3.{h,eds}` then the compiler checks if this is present in `path_of_file1/path_of_file2/a/new/path/to/file3.{h,eds}`.
- If the necessary file is not found with the method above, the compiler assumes that is it a library file and searches for it by
following the method that is described in the next section about Library Functions.

### Library Functions
- The prepackaged static library of edsger, is written in C. (`path/to/edsger/src/lib/lib-implementation/`)
Each function is in its own file so that we can easily avoid function redefinitions during linking. (Not the best solution 🐧)
- The header files for this prepackaged library are provided in `path/to/lib/lib-headers/`.
- When compiling a program, the necessary library headers as well as the archive file of the static library should be present in 
the same directory as the source file. If they are, they are used for the compilation. If they are **not**, the compiler searches 
in `$EDS_LIB_DIR/lib-headers/` for the headers, and in `$EDS_LIB_DIR/` for the static library. Thus the `~/.bashrc` file should 
be set accordingly (or just the environment if it's a one time execution of the compiler) and `edsgerlib.a` should be present in 
`$EDS_LIB_PATH/`.
- All `writeXYZ()` functions do not print any newline characters but only the input they are provided.
- `writeBoolean(bool b)` prints the string "true" if b is equal to `true` and "false" otherwise.
- `writeString(char *s)` prints the characters of the string s, until the first null byte is found.
- `readChar ()` does not "read" whitespaces. It is implemented by calling `scanf(" %c", &ref)`.
- `readString (int size, char * s)` reads at most `size - 1` characters from `stdin` and null-terminates the string properly, by 
placing a null byte as the `size`-th character in the provided buffer. The function reads from `stdin` as long as it has not 
reached `EOF` or it not read the newline char `'\n'`. The `'\n'` is not included in the returned string.

## Language Feature Implementation Details

### Variable Types And Constants
- In edsger the available variable types are `int`, `bool`, `char`, `double` and `t*`, where `t` is another valid type.
- `int`s are 2 bytes long, `bool`s are 1 byte long as well as `char`s. `double`s are 8-bytes long.
- The programmer can only type unsigned constants in a program. This means that the maximum `int` constant that can be
typed in a program is equal to `32767`. Even though `-32768` is a valid 2 bytes long value, in edgser `-` is an operator
and not a part of the integer constant that the programmer can write. Thus, `-32768` **cannot** be written in an edsger 
program by the programmer.
- When an integer variable holds a value bigger than `32767` or smaller than `-32768`, we've reached integer overflow
territory. Of course, nobody should depend on integer overflow behaviour when writing their programs. 

### Function Declarations
- A declaration of a function and a definition of the same function do not have to agree in the name of the parameters.
(C-like function declaration)
- A declaration of a function cannot be placed after the definition of the same function.

### Function Overloading
- We allow function overloading.
- We do not allow the declaration of two functions with the same name and equivalent parameter lists. Two parameters are equivalent
if they have the same type. (We do not care about the pass method) Two parameter lists are equivalent if their contents are equivalent.
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

### Nested Functions
- In edsger, the programmer can nest functions. The nested functions can access variables from the outer scopes in which 
they are nested into, as expected. This is implemented via lambda lifting.
- With Lambda Lifting we add extra hidden parameters to functions when they are needed.
1. A variable does not need to be lambda lifted if it is global and it hasn't been shadowed by another variable.
2. A variable does not need to be lambda lifted if it is defined in the function which uses it. (as a local variable or as a parameter)
3. If a function uses a variable for which neither 1. or 2. hold, then that variable must be lambda lifted.
4. A "parent" function should lift the "required" variables that its nested functions lambda lifted. 
A variable that has been lifted by a nested function, is "required" to be lifted if it has not been bound by the parent function before the nested function definition.

### Local Variable Declarations
- It is not guaranteed that local variables are initialized to zero. 
- It is not allowed to declare a variable that has the same name as a parameter or another variable inside a function.
The same principle applies to parameter declaration.

### Static Array Declarations
- When defining an array statically, the size of the array must be a **positive** constant integer expression. A constant 
integer expression is a constant expression of type int, defined as stated below: <br>
    > A constant integer expression can be:
    > 1. a constant int
    > 2. the result of the operations '+', '-', '*', '/', '%'
    > between two <ins>constant integer expressions</ins>
    > 3. a constant double, casted to an int
    > 4. the result of the operations '+', '-', '*', '/', '%'
    > between two constant doubles, casted to an int.
- These constant integer expressions are computed by the compiler during compile time.
- Global arrays are initialized to contain zeros. This is not guaranteed when declaring a local static array.

### Dynamic Memory Allocation
- The programmer can dynamically allocate memory via the `new` operator. As it is expected, the length of the allocated 
memory space is variable. (And is resolved during runtime) The `new` operator is just a call to the `malloc` function.
The implementation of `malloc` is linked when our compiler is calling the `clang` compiler, to link the produced assembly 
file with the prepackaged static library. 

#### Note ⚠️ 
The `new` operator (or the equivalent `malloc` call) does not fail when the provided size is equal to 0 or a negative 
number. Special care should be given, if the `new` operator is called with a negative number as its size, since `malloc`
accepts unsigned integers, thus it will allocate memory with the equivalent unsigned size.

- The programmer can and should deallocate the dynamically allocated memory via the `delete` operator. In this implementation
of edsger, no garbage collector exists. The `delete` operator is equivalent to a call to the `free` function. Whatever applied
for the implementation of `malloc` and the linking, applies for `free` as well.
- Using the `delete` operator, deletes (🐧!!) the data of the allocated data block.
- One may not `delete` non dynamically allocated memory or already `delete`d memory.

### Erroneous Accesses
- String constants are immutable, attempting to mutate them results in `Segmentation Fault`.
- In this implementation of the edsger language, there are no checks for out of bounds array accesses. As long as the offset
of an access is within reasonable sizes etc. no restriction is applied. A `Segmentation Fault` might occur when the address
is not within the valid memory space that is accessible from the edsger program.
- A segmentation fault occurs when trying to store a value to a `NULL` pointer.
- When executing an infinite recursive program, the program most probably terminates due to `Segmentation Fault` because
of "stack overflow", that resulted in an erroneous memory access)
- One can access a `delete`d "memory block" and modify its values. However this is not suggested, as this "block" can be 
reallocated at any given time.

#### Known issue ⚠️ <br>
When trying to change the "contents" of a `NULL` pointer, it usually results in `Segmentation Fault`. However, if the user 
has enabled optimizations, they might face an `Illegal instruction` message (and the program terminates on the same line of code), 
or no messages at all depending on the user's setup & LLVM version.
Since the erroneous access results in Undefined Behaviour, the LLVM optimizer simply replaces this access with an "undefined opcode" instruction. [Related terms: `llvm.trap()` (LLVM API) & `ud2` (x86 IS) etc.]

### Labels
- We do not allow two labels in the same function to have the same name.
- We only allow jumps to a label if the "jump" command is nested in the body of the labeled for-loop that is the jump 
destination.

### Type Casting
- We allow every possible type casting between numerical types (`int`, `char`, `bool`, `double`).
- We only allow a pointer to be cast to an `int` and no other numerical type.
- We do not allow any numerical value to be cast into a pointer.
- We allow casting between pointer types freely.
#### Casting rules
  1. To `int`
      1. A `char` is converted to its respective ASCII code. (equivalent to the `ord` function of `stdlib.h`)
      2. A `bool` is converted to `1` if it is equal to `true` and to `0` otherwise.
      3. A `double` is converted to the equivalent "truncated" `int` value.
      4. A pointer is converted to the base 10 representation of the address that it points to.
  2. To `char`
      1. An `int` is converted to a `char` value by truncating it bits to the size of the `char` type. 
      2. A `bool` is converted to a `char` by zero extending its bits.
      3. A `double` is converted to a `char` by rounding it to the nearest unsigned `int` and then converting it
      to the `char` with that ASCII Code. In case of a negative number, the result is undefined.
  3. To `bool`
      1. Every non-zero `int` value is converted to `true`. Otherwise, it is converted to `false`.
      2. Every non-zero `double` value is converted to `true`. Otherwise, it is converted to `false`.
      3. Every non-zero ASCII Code `char` value is converted to `true`. Otherwise, it is converted to `false`.
  4. To `double`
      1. An `int` value is casted to a `double` value of the same sign, with a zeroed out decimal part. 
      2. A `char` value is casted to a positive `double` value with a zeroed out decimal part, that corresponds to the
      character's ASCII code. 
      4. A `bool` value is casted to a positive `double` value with a zeroed out decimal part. It is equal to `1.0` when
      the value is equal to `true` and `0.0` otherwise.
      
  5. To `pointer`
      1. Only a pointer can be converted to another pointer. When converting a pointer, the code that is produced by 
      the compiler does **not** convert the data that the pointer points to. The resulting pointer simply "acts" like 
      it points to data that have the type that is implied from the casting clause. 

#### Known issue ⚠️ <br>
Accessing a type casted pointer is unstable and can give different results, depending on if the user enabled optimizations or not.
In general, pointer type casting is to be avoided. :)

## Miscellaneous

### Grammar Conflicts
- The grammar of the Edsger language is provided at p. 15, in the specification that we linked at the beggining of this document.
It is an ambiguous grammar. 
- Most of the conflicts (binary operators, dangling else) were solved by enforcing precedence and 
associativity rules. (`%left`, `%right`, `%nonassoc` directives)
- One of those conflicts was resolved via semantic actions. Specifically, there is a **reduce-reduce** conflict between the argument list
of a function call and the comma operator.

eg. 
``` 
int f (int x){
  // Some code
  // Return some value
}

int f (int x, int y){
  // Some code
  // Return some value
}

void main (){
  int x, int y;
  // some code
  f(x, y); // This should be interpreted as two arguments? Or should this return y? (Comma operator)
  // More code
} 
```

We concluded that when providing an argument list, a comma operator **must** be between parentheses, meaning that if we want to call 
the first function named `f` we should write `f((x, y))`, while `f(x, y)` is a call corresponding to the second function named `f`. 
In order to achieve that, we changed the production rule for a function call to: `<I>([<expression>])`. Thus, `test(x, y, z)` is at 
first equivalent to `<I> -> test` and `<expression> -> Comma(Comma(x,y),z)`, since `Comma` is left-associative. The only thing we have 
to do is to flatten this list of `Comma` nodes. That's what we do in practice. We allow the parser to use `Comma` nodes to construct the 
argument list of a function call, but before returning this argument list, we flatten any `Comma` node that is not between parentheses.

Snippet of the source code that does the described flattening: 
```
let rec flatten ex acc =
  match ex.expr with
    | E_binop (x, O_comma, y) -> flatten x (y :: acc)
    | _ -> ex :: acc
```

#### Note
The preceding snippet is a modified version of the `flatten_commas` function that exists in this [repository](https://github.com/angelakis/Edsger-Compiler/blob/master/Parser.mly).

### Order of Evaluations
- The operator `op =` is right associative. Thus, we choose to evaluate the operands from right to left (!) unlike the other binary 
operators where the operands are evaluated from left to right.

eg. Consider the expression `b += b *= 2;` with `b` initialized to 10. Then, the expression is computed as `b += (b *= 2)` and 
`(b *= 2)` is evaluated before the `b` on the LHS of the expression. Thus, after the expression, `b` is equal to 40 and not 30.
