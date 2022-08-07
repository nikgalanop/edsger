type mode = Warning | Error

(* Function for printing warning or error diagnostic messages. *)
val print_diagnostic : p : Lexing.position option -> string -> mode -> unit