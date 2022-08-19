open Identifier
open Types 

let primitive_sem = function 
  | Ast.INT -> TYPE_int 
  | Ast.CHAR -> TYPE_char
  | Ast.BOOL -> TYPE_bool 
  | Ast.DOUBLE -> TYPE_double 

let rec str_of_type = function 
  | TYPE_none -> "none"
  | TYPE_int -> "int"
  | TYPE_bool -> "bool"
  | TYPE_char -> "char"
  | TYPE_double -> "double"
  | TYPE_pointer { typ = t; 
    dim = d; mut = m } -> 
      (str_of_type t) ^ String.make d '*'      
  | TYPE_null -> "null"
  | TYPE_proc -> "void"

(* let str_of_param p =
  let t = str_of_type p.parameter_type in
  match p.parameter_mode with
  | PASS_BY_VALUE -> t
  | PASS_BY_REFERENCE -> "byref " ^ t

let rec str_of_params = function 
  | [] -> ""
  | h :: t -> match h with
    | ENTRY_parameter inf -> let s = (str_of_param inf) in 
      if (t = []) then s else s ^ ", " ^ (str_of_params t)
    | _ -> failwith "Should not find a non-parameter."  *)

let str_of_params p = ""

let str_of_func frt n p = 
  (str_of_type frt) ^ " " ^ n 
    ^ "(" ^ (str_of_params p) ^ ")"

let id_of_func n ps = (* Must change to accept parameters *)
  id_make @@ "fun_" ^ n ^ "_" ^  (* TODO: Currently ignores overloading. *)
let id_of_var n = 
  id_make @@ "var_" ^ n
let id_of_label l = 
  id_make @@ "label_" ^ l

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
let is_assignable t exp = 
  (not @@ is_null exp) && is_mut t && is_lval exp