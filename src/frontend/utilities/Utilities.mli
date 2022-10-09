(* Type of the diagnostic message to be printed. *)
type printmode = Warning | Error

(* Function for printing warning or error diagnostic messages. *)
val print_diagnostic : p : Lexing.position option -> string -> printmode -> unit

val static_lib_dir : unit -> string
val default_lib_header : string -> string