type mode = Warning | Error;;

val print_msg : Lexing.position -> string -> mode -> unit