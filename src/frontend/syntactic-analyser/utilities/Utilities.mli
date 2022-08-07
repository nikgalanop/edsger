type printmode = Warning | Error

type decl = FDecl of string | FDef of string

(* Function for printing warning or error diagnostic messages. *)
val print_diagnostic : p : Lexing.position option -> string -> printmode -> unit

val fail_sem : string -> decl -> 'a