(* Returns the lexical analyzing function *)
val lexer : Lexing.lexbuf -> Parser.token

(* Create a buffer from stdin *)
val add_stdin : unit -> Lexing.lexbuf

(* Create a buffer from an existing file *)
val add_file : string -> Lexing.lexbuf 

exception LexFailure of Lexing.position * string 