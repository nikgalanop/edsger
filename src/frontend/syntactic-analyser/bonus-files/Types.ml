type typ = TYPE_none
         | TYPE_int
         | TYPE_bool
         | TYPE_char
         | TYPE_double
         | TYPE_pointer of typ * int
         | TYPE_array of typ * int
         | TYPE_proc

(* Maybe add TYPE_NULL? *)
(* TYPE_pointer VS TYPE_array?? *)

let rec sizeOfType t =
   match t with
   | TYPE_int            -> 2
   | TYPE_bool           -> 1
   | TYPE_char           -> 1
   | TYPE_double         -> 10
   | TYPE_pointer (_, _) -> 2
   | TYPE_array (et, sz) -> sz * sizeOfType et
   | _                   -> 0

let rec equalType t1 t2 =
   match t1, t2 with
   | TYPE_array (et1, sz1), TYPE_array (et2, sz2) -> equalType et1 et2
   | TYPE_pointer (et1, d1), TYPE_pointer (et2, d2) -> equalType et1 et2 && d1 = d2 
   | _                                            -> t1 = t2
