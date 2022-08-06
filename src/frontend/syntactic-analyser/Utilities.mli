type mode = Warning | Error;;

val print_diagnostic : p : Lexing.position option -> string -> mode -> unit