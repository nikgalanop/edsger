(* Returns the lexical analyzing function *)
val lexer : Lexing.lexbuf -> Parser.token

(* Create a buffer from an existing file *)
val add_file : string -> Lexing.lexbuf 

(* When the lexical analyser fails to do something, like 
   opening a file etc. it raises a LexFailure exception 
   that contains metadata about the position that the 
   error was found, as well as a message describing the
   error.*)
exception LexFailure of Lexing.position * string 