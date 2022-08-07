type typ = TYPE_none
         | TYPE_int
         | TYPE_bool
         | TYPE_char
         | TYPE_double
         | TYPE_pointer of { typ : typ; dim : int; mut : bool }       
         | TYPE_null
         | TYPE_proc

(* Maybe add TYPE_NULL? *)

let rec sizeOfType t =
   match t with
   | TYPE_int            -> 2
   | TYPE_bool           -> 1
   | TYPE_char           -> 1
   | TYPE_double         -> 10
   | TYPE_pointer _      -> 2
   | TYPE_null           -> 2 (* A pointer *) 
   | _                   -> 0

(* Add TYPE_null in this function. *)
let rec equalType t1 t2 =
   match t1, t2 with
   | TYPE_pointer {typ = et1; dim = _; mut = _},
     TYPE_pointer {typ = et2; dim = _; mut = _} -> equalType et1 et2 (* Do we need to check about "mutability" equality? *)
   | TYPE_pointer r, TYPE_null when r.mut -> true 
   | TYPE_null, TYPE_pointer r when r.mut -> true 
   | _                                            -> t1 = t2
