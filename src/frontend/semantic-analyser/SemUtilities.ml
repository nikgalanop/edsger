open Identifier
open Symbol
open Types 

let primitive_sem = function 
  | Ast.INT -> TYPE_int 
  | Ast.CHAR -> TYPE_char
  | Ast.BOOL -> TYPE_bool 
  | Ast.DOUBLE -> TYPE_double 

let rec str_of_type ~ptr_format = function 
  | TYPE_none -> "none"
  | TYPE_int -> "int"
  | TYPE_bool -> "bool"
  | TYPE_char -> "char"
  | TYPE_double -> "double"
  | TYPE_pointer { typ = t; 
    dim = d; mut = m } -> 
    let dim_str = if (ptr_format) then String.make d '*' 
    else string_of_int d in (str_of_type ~ptr_format:false t) ^ dim_str       
  | TYPE_null -> "null"
  | TYPE_proc -> "void"

let str_of_func ft n pstr = 
  (str_of_type ~ptr_format:true ft) ^ " " ^ n 
    ^ " (" ^ pstr ^ ")"

let rec sep_but_last f = function 
  | [] -> ""
  | [x] -> f x
  | h :: t -> f h ^ ", " ^ sep_but_last f t

let header_of_astf ft n ps = 
  let ptr_str vt = 
    let Ast.PTR (ptyp, dim) = vt in 
    str_of_type ~ptr_format:true (primitive_sem ptyp) ^ (String.make dim '*')
  in let aux = function 
    | Ast.BYREF (vt, _) -> "byref" ^ ptr_str vt
    | Ast.BYVAL (vt, _) -> ptr_str vt
  in let pstr = sep_but_last aux ps in
  str_of_func ft n pstr

let header_of_symbolf ft n ps = 
  let str_of_param p =
    let t = str_of_type ~ptr_format:true p.parameter_type in
    match p.parameter_mode with
    | PASS_BY_VALUE -> t
    | PASS_BY_REFERENCE -> "byref " ^ t
  in let aux entr = 
    match entr.entry_info with 
    | ENTRY_parameter inf -> str_of_param inf
    | _ -> failwith "Should not find a non-parameter."
  in let pstr = sep_but_last aux ps in
  str_of_func ft n pstr

let str_of_fval_types vtyps =
  List.fold_right ( ^ ) (List.map (str_of_type ~ptr_format:false) vtyps) ""

let name_mangling ps = 
  let aux = function 
    | Ast.BYREF (vt, _) | Ast.BYVAL (vt, _) -> 
      let Ast.PTR (ptyp, dim) = vt in 
      let dim_str = if (dim > 0) then string_of_int dim else "" in
      str_of_type ~ptr_format:false (primitive_sem ptyp) ^ dim_str
  in
    List.fold_right ( ^ ) (List.map aux ps) "" 

(* Name Mangling: https://en.wikipedia.org/wiki/Name_mangling *)
(* We do not allow overloading cases like the following:
  void test (int a); 
  int test (byref int x); 
  since the byref declaration (or definition) would never be used.*)  
let id_of_func n pstr = 
  id_make @@ "fun_" ^ n ^ "_" ^ pstr 
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