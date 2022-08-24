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

let typ_of_primitive = function 
  | Ast.INT -> TYPE_int 
  | Ast.CHAR -> TYPE_char
  | Ast.BOOL -> TYPE_bool 
  | Ast.DOUBLE -> TYPE_double


let rec is_const (exp : Ast.ast_expr) = 
  match exp.expr with 
  | E_int _ | E_bool _ | E_double _ 
  | E_char _ | E_NULL | E_str _ -> true
  | E_uop (O_psgn, e) | E_uop (O_nsgn, e) 
  | E_uop (O_neg, e)  -> is_const e
  | E_binop (e1, _, e2) -> 
    is_const e1 && is_const e2
  | E_tcast (v, e) -> is_const e
  | E_ternary (e1, e2, e3) ->
    is_const e1 && is_const e2 && is_const e3
  | E_brack e -> is_const e
  | _ -> false
let is_null (exp : Ast.ast_expr) = 
  match exp.expr with
  | E_NULL -> true 
  | _ -> false
let is_mut = function 
  | TYPE_pointer r -> r.mut 
  | _ -> true
let rec is_lval (exp : Ast.ast_expr) = 
  match exp.expr with
  | E_brack e -> is_lval e
  | E_var _ | E_uop (O_dref, _) | E_arracc (_, _) -> true 
  | _ -> false  
let is_ptr = function 
  | TYPE_pointer _ -> true 
  | _ -> false
let is_assignable t (exp : Ast.ast_expr) = 
  (not @@ is_null exp) && is_mut t && is_lval exp
