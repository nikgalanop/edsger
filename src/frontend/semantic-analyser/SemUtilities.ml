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

(* Name Mangling: https://en.wikipedia.org/wiki/Name_mangling *)
(* We do not allow overloading cases like the following:
  void test (int a); 
  int test (byref int x); 
  since the byref declaration (or definition) would never be used.*) 
let name_mangling ps = 
  let aux = function 
    | Ast.BYREF (vt, _) | Ast.BYVAL (vt, _) -> 
      let Ast.PTR (ptyp, dim) = vt in 
      let dim_str = if (dim > 0) then string_of_int dim else "" in
      str_of_type ~ptr_format:false (primitive_sem ptyp) ^ dim_str
  in
    List.fold_right ( ^ ) (List.map aux ps) ""  

let exists_main () = 
  let id = Identifier.id_of_func "main" "" in
  try
    let e = lookupEntry id LOOKUP_CURRENT_SCOPE true in
    match e.entry_info with 
    | ENTRY_function inf -> begin 
      let rt = inf.function_result in 
      let params = inf.function_paramlist in
      if (rt <> TYPE_proc || params <> []) then
        failwith "Did not find a `void main ()` function in the global scope."
      end
    | _ -> 
      failwith "Found a non-function with an identifier of a function."
  with Exit -> 
    failwith "Did not find a `void main ()` function in the global scope."

let check_jmp = function 
  | Some l -> begin 
      let id = Identifier.id_of_label l in 
      try
        ignore @@ lookupEntry id LOOKUP_ALL_SCOPES true;
        true
      with Exit -> false
    end
  | None -> true 