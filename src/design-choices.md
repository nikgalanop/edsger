### Filenames:
- The input file to the compiler, must have the extension `.eds`.
- An "included" file must have either the extension `.eds` or `.h`.

### Overloading:
- We allow function overloading.
- We do not allow the declaration of two functions with the same 
name and equivalent parameter lists. Two parameters are equivalent
if they have the same type. (We do not care about the pass method)
Two parameter lists are equivalent if their contents are equivalent.

### Type Casting:
- We allow every possible type casting between arithmetic types.
- We only allow a pointer to be cast to an int.
- We do not allow any arithmetic value to be cast into a pointer.
- We allow casting between pointer types freely.

### Labels:
- We do not allow two labels in the same function to have the same name.
- We only allow jumps to a label if the "jump" command is nested in the 
body of the labeled for-loop that is the jump destination.

### Static Array Declarations:
- When defining an array statically, the size of the array must be
a **positive** constant integer expression. A constant integer 
expression is a constant expression of type int, defined as stated below:
    > A constant integer expression can be:
    > 1. a constant int
    > 2. the result of the operations '+', '-', '*', '/', '%'
    > between two <ins>constant integer expressions</ins>
    > 3. a constant double, casted to an int
    > 4. the result of the operations '+', '-', '*', '/', '%'
    > between two constant doubles, casted to an int.
- Global arrays are initialized to contain zeros. This is not guaranteed
when declaring a local static array.

## Library Functions
- `readChar ()` does not "read" whitespaces. It is implemented by calling 
`scanf(" %c", &ref)`.
- `readString (int size, char * s)` reads at most `size - 1` characters from 
`stdin` and null-terminates the string properly. (Added as the `size`-th 
character in the provided buffer. The function reads from `stdin` as long 
as it has not reached `EOF` or it not read the newline char `'\n'`. The `'\n'` 
is not included in the returned string.
