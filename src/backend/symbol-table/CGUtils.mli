val get_ast_param_name  : Ast.parameter -> string
val funStr_mangled : string -> string -> int -> string
val filter_env     : Ast.parameter list -> Ast.parameter list -> 
                    Ast.parameter list option
val typ_of_vartype : Ast.vartype -> Types.typ