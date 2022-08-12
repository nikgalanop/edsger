exception SemFailure of Lexing.position * string

val sem_analysis : Ast.ast -> unit