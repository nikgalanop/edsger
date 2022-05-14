val lexer : Lexing.lexbuf -> Parser.token
val init : unit
val push_buffer : Lexing.lexbuf -> unit
val current_buffer : Lexing.lexbuf