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
   | TYPE_pointer {typ = t1; dim = d1; mut = m1},
     TYPE_pointer {typ = t2; dim = d2; mut = m2}, -> equalType et1 et2 && m1 = m2
   (* | TYPE_pointer (_, _), TYPE_null -> true (* I don't like the fact that the order matters but in 
                                               an assignment TYPE_null should not be on the LHS. 
                                               Maybe do not take care of it here? *) *)
   | _                                            -> t1 = t2
