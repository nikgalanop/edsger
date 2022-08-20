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

let is_null exp = 
  match exp.expr with
  | E_NULL -> true 
  | _ -> false
let is_mut = function 
  | TYPE_pointer r -> r.mut 
  | _ -> true
let rec is_lval exp = 
  match exp.expr with
  | E_brack e -> is_lval e
  | E_var _ | E_uop (O_dref, _) | E_arracc (_, _) -> true 
  | _ -> false  
let is_ptr = function 
  | TYPE_pointer _ -> true 
  | _ -> false
let is_assignable t exp = 
  (not @@ is_null exp) && is_mut t && is_lval exp
