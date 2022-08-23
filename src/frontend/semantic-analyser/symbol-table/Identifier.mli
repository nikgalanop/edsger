(* Hash consed identifiers *)

type id

val id_make  : string -> id
val id_name  : id -> string
val pretty_id : Format.formatter -> id -> unit

val id_of_func : string -> string -> id 
val id_of_var : string -> id
val id_of_label : string -> id

val ent_name_of_id : id -> string 