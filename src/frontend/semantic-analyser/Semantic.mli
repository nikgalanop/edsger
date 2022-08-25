(* Semantic analysis of an AST. On success it returns a unit. *)
val sem_analysis : Ast.ast -> unit

(* On failure, the sem_analysis function raises a SemFailure
   Exception that contains metadata about the position that 
   the error was found, as well as a message describing the
   error. *)
exception SemFailure of Lexing.position * string
