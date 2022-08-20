type typ = TYPE_none        (* no type (should not be used)       *)
         | TYPE_int         (* int                                *)
         | TYPE_bool        (* bool                               *)
         | TYPE_char        (* char                               *)
         | TYPE_double      (* double                             *)                      
         | TYPE_pointer of { typ : typ; dim : int; mut : bool }       
         | TYPE_null
         | TYPE_proc        (* proc (return type)                 *)

val equalType : typ -> typ -> bool

val is_null : Ast.ast_expr -> bool
val is_mut : typ -> bool
val is_lval : Ast.ast_expr -> bool
val is_ptr : typ -> bool
val is_assignable : typ -> Ast.ast_expr -> bool