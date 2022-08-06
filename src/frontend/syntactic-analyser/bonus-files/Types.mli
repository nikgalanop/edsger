type typ = TYPE_none        (* no type (should not be used)       *)
         | TYPE_int         (* int                                *)
         | TYPE_bool        (* bool                               *)
         | TYPE_char        (* char                               *)
         | TYPE_double      (* double                             *)                      
         | TYPE_pointer of { typ : typ; dim : int; mut : bool }       
         | TYPE_null
         | TYPE_proc        (* proc (return type)                 *)

val sizeOfType : typ -> int
val equalType : typ -> typ -> bool
