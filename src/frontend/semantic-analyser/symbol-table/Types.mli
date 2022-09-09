type typ = TYPE_none        
         | TYPE_int         
         | TYPE_bool        
         | TYPE_char        
         | TYPE_double                            
         | TYPE_pointer of { typ : typ; dim : int; mut : bool }       
         | TYPE_null
         | TYPE_proc        

val equalType : typ -> typ -> bool

val typ_of_primitive: Ast.primitive -> typ

val valid_cast : typ -> typ -> bool

val is_const : Ast.ast_expr -> bool
val is_null : Ast.ast_expr -> bool
val is_mut : typ -> bool
val is_lval : Ast.ast_expr -> bool
val is_ptr : typ -> bool
val is_assignable : typ -> Ast.ast_expr -> bool