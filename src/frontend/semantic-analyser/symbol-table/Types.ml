type typ = TYPE_none
         | TYPE_int
         | TYPE_bool
         | TYPE_char
         | TYPE_double
         | TYPE_pointer of { typ : typ; dim : int; mut : bool }       
         | TYPE_null
         | TYPE_proc

let rec equalType t1 t2 =
   match t1, t2 with
   | TYPE_pointer {typ = et1; dim = _; mut = _},
     TYPE_pointer {typ = et2; dim = _; mut = _} -> equalType et1 et2 
   | TYPE_pointer r, TYPE_null | TYPE_null, TYPE_pointer r -> 
      r.mut 
   | _                                            -> t1 = t2
