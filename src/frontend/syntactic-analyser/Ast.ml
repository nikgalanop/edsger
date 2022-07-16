(* 
   We most probably need something more powerful 
   rather than a simple D_var list for function 
   parameter lists since we have to deal with 
   byref instances.
*)
type var = string
type fname = string
type label = string
type uop = O_ref | O_dref | O_psgn | O_nsgn | O_neg
type binop = O_times | O_div | O_mod | O_plus | O_minus
             | O_lt | O_gt | O_ge | O_eq | O_neq 
             | O_and | O_or | O_comma
type uassign = O_plpl | O_mimi
type bassign = O_asgn | O_mulasgn | O_divasgn 
              | O_modasng | O_plasgn | O_minasgn


type primitive = INT | CHAR | BOOL | DOUBLE 
and vartype =  PTR of primitive * int
and rettype = VOID | RET of vartype

type parameter = 
{
  n : var; 
  t : vartype; 
  byref : bool
}

type ast_decls 
  | D_var of var * vartype
  | D_fun of fname * rettype * (parameter list) option  (* Reconsider the parameter list type *)
  | D_fdef of fname * rettype * (parameter list) option * ast_body (* Reconsider the parameter list type *)
and ast_body
  | F_body of (ast_decls) list * (ast_stmt) list 
and ast_stmt (* <expr> ";" is a statement. So is ";". Think about that. *) 
   (* Revise the current ones and check what is going on with continue/break/return *)
  | S_block of ast_stmt list
  | S_if of ast_expr * ast_stmt * (ast_stmt) option 
  | S_for of (ast_expr) option * (ast_expr) option * (ast_expr) option * ast_stmt * (label) option
  | S_cont of (label) option 
  | S_break of (label) option
  | S_ret of (ast_expr) option
  | S_TODO
and ast_expr
  | E_var of var (* I don't know if this the correct implementation*)
  | E_int of int (* Should these be the OCAML types? *)
  | E_char of char 
  | E_double of float 
  | E_str of string
  | E_bool of bool
  | E_uop of uop * ast_expr
  | E_binop of ast_expr * binop * ast_expr
  | E_uasgnpre of uassign * ast_expr
  | E_uasgnpost of ast_expr * uassign
  | E_basgn of ast_expr * binop * ast_expr
  | E_tcast of vartype * ast_expr
  | E_ternary of ast_expr * ast_expr * ast_expr
  | E_new of vartype * (ast_expr) option 
  | E_delete of ast_expr
  | E_TODO
(* 
  Have to add "function calls", "array accesses",
  unary operators, binary operators, unary assignments 
  (prefix and postfix!! order matters), binary assignment,
  (type casting ??), ternary operator and new/delete stmts.
*)