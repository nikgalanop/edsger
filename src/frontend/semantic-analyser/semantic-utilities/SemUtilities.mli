val str_of_type : short : bool -> ptr_format : bool -> 
                Types.typ -> string 
val header_of_astf : Types.typ -> Ast.fname ->
                    Ast.parameter list -> string 
val header_of_symbolf : Types.typ -> Ast.fname -> 
                        Symbol.entry list -> string
val str_of_fval_types : Types.typ list -> string
val str_of_fcall : Ast.fname -> Types.typ list -> string
val name_mangling : Ast.parameter list -> string
val exists_main : unit -> unit
val check_jmp : Ast.label option -> bool
  