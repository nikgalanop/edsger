type typ = TYPE_none        (* no type (should not be used)       *)
         | TYPE_int         (* int                                *)
         | TYPE_bool        (* bool                               *)
         | TYPE_char        (* char                               *)
         | TYPE_double      (* double                             *)                      
         | TYPE_array of    (* array                              *)
             typ *          (* element type                       *)
             int            (* size of array, if known, or zero   *)
         | TYPE_pointer of 
             typ *          (* element type                       *)
             int            (* "dimension" of pointer             *)
         | TYPE_null
         | TYPE_proc        (* proc (return type)                 *)

val sizeOfType : typ -> int
val equalType : typ -> typ -> bool
