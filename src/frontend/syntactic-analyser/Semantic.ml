open Ast
open Symbol 

let add_variables v l = ()
let add_declaration = ()

let is_lval = function 
  | E_var _ | E_uop (O_dref, _) | E_arracc (_, _) -> true 
  | _ -> false  
let is_ptr = function 
  | TYPE_pointer (_, _) -> true 
  | _ -> false

let sem_uop t = function 
  | O_ref -> TYPE_none (* TODO *)
  | O_dref -> TYPE_none (* TODO *)
  | O_psgn -> if (equalType t TYPE_int || equalType t TYPE_double) then t
              else failwith "Cannot specify sign of non numerical value."
  | O_nsgn -> if (equalType t TYPE_int || equalType t TYPE_double) then t
              else failwith "Cannot specify sign of non numerical value."
  | O_neg -> if (equalType t TYPE_bool) then t 
             else failwith "Cannot negate a non-boolean."
let sem_binop t1 t2 = function
  | O_times -> TYPE_none (* TODO *)
  | O_div -> TYPE_none (* TODO *)
  | O_mod -> TYPE_none (* TODO *)
  | O_plus -> TYPE_none (* TODO *)
  | O_minus -> TYPE_none (* TODO *)
  | O_lt -> TYPE_none (* The comparison operators need work. Check the specification for more details. *)
  | O_gt -> TYPE_none (* TODO *)
  | O_le -> TYPE_none (* TODO *)
  | O_ge -> TYPE_none (* TODO *)
  | O_eq -> if (equalType t1 t2) then t1 
            else failwith "Cannot apply '==' on operands of different type." 
  | O_neq -> if (equalType t1 t2) then t1 
             else failwith "Cannot apply '!=' on operands of different type."
  | O_and -> if (equalType t1 TYPE_bool && equalType t2 TYPE_bool) then t1 
             else failwith "Cannot apply 'and' on non-booleans."
  | O_or -> if (equalType t1 TYPE_bool && equalType t2 TYPE_bool) then t1 
            else failwith "Cannot apply 'or' on non-booleans."
  | O_comma -> t2
let sem_uasgn t = 
  match t with  
  | TYPE_int | TYPE_double | TYPE_pointer (_, _) -> t
  | _ -> failwith "Cannot increment/decrement a non-numerical value or a non-pointer."
let sem_basgn t1 t2 = function 
  | O_asgn -> if (equalTypes t1 t2) then t1
              else failwith "Tried an assignment with values of different types."
  | O_mulasgn | O_divasgn | O_modasgn | O_plasgn | O_minasgn -> TYPE_none (* TODO *)   

(* IMPORTANT CONSIDERATION: IN ASSIGNMENTS WE MUST CHECK WHETHER OR NOT THE LHS IS AN L-VALUE. *)
(* Something that I am not 100% if it's completely implemented. *)

(* IMPORTANT CONSIDERATION: MAKE SURE THAT NULL CAN BE ASSIGNED TO A POINTER OF ANY TYPE. *)

let rec sem_expr = function
  | E_var s -> TYPE_none (* TODO: Check the interface of the symbol table. *)
  | E_int _ -> TYPE_int
  | E_char _ -> TYPE_char
  | E_double _ -> TYPE_double
  | E_str s -> TYPE_pointer (TYPE_char, 1) (* String are null-terminated "arrays" of characters. (Specification p. 9) *)
  | E_bool _ -> TYPE_bool
  | E_NULL -> TYPE_none (* Maybe add type_null? Null is supposed to be a pointer of "any" type. *)
  | E_uop (op, e) -> let t = sem_expr e in sem_uop t op
  | E_binop (e1, op, e2) -> let t1 = sem_expr e1 in let t2 = sem_expr e2 in sem_binop t1 t2 op
  | E_uasgnpre (ua, e) -> if (is_lval e) then let t = sem_expr e in sem_uasgn t 
                          else failwith "Tried to increment/decrement something non-assignable."
  | E_uasgnpost (ua, e) -> if (is_lval e) then let t = sem_expr e in sem_uasgn t 
                           else failwith "Tried to increment/decrement something non-assignable."
  | E_basgn (e1, op, e2) -> if (is_lval e) then let t1 = sem_expr e1 in let t2 = sem_expr e2 in sem_basgn t1 t2 op
                            else "Tried to assign a value to something non-assignable."  
  | E_tcast (v, e) -> eprintf "E_tcast(%s, " (vartype_str v); print_expr e;
  | E_ternary (e1, e2, e3) -> let t1 = sem_expr e1 in let t2 = sem_expr e2 in let t3 = sem_expr e3 in 
                              if (equalType t1 TYPE_bool) then 
                                  if (equalType t2 t3) then t2  
                                  else failwith "Return values of ternary statement do not have the same type." 
                              else failwith "Non-boolean condition in ternary statement."
  | E_new (v, e) ->  TYPE_none
                     (* How to make sure that e is a *POSITIVE* integer? 
                        I believe that it is not possible at this "stage" of the compilation. *)
                     (* Size of array not known in compile time afaik. *)
  | E_delete (e) -> let t = sem_expr e in 
                    if (is_ptr t) then TYPE_none (* TODO: Should make sure that the pointer of e, actually points somewhere. *)
                    else failwith "Tried to deallocate memory using a non-pointer."
  | E_fcall (f, l) -> TYPE_none (* TODO: Check existance of function and that the provided values match the parameters. *)
                                (* ! ALSO CHECK THAT FOR BYREF PARAMETERS, WE DON'T PROVIDE CONSTANT VALUES. ! *)
  | E_arracc (e1, e2) -> TYPE_none (* How to make sure that e2 is a *POSITIVE* integer within the bounds of the array (or "ptr" array) ? 
                                      I believe that it is not possible at this "stage" of the compilation.*)
  | E_brack (e) -> sem_expr e
and sem_stmt = function
  | S_NOP -> ()
  | S_expr e -> sem_expr e;
  | S_block l -> openScope (); List.iter sem_stmt s; closeScope ();
  | S_if (e, s, None) -> eprintf "S_if ("; print_expr e; eprintf ","; print_stmt s; eprintf ")"
  | S_if (e, s1, Some s2) -> eprintf "S_if ("; print_expr e; eprintf ","; print_stmt s1; eprintf ","; print_stmt s2; eprintf ")"
  | S_for (o1, o2, o3, s, l) -> eprintf "S_for("; for_expr o1; for_expr o2; for_expr o3; print_stmt s; eprintf ", "; for_label l; eprintf ")"
  | S_cont l -> eprintf "S_cont(%s)" (label_str l)
  | S_break l -> eprintf "S_break(%s)" (label_str l)
  | S_ret None -> eprintf "S_ret()"
  | S_ret Some e -> eprintf "S_ret("; print_expr e; eprintf ")"
and sem_body b = 
  let F_body (d, s) = b in
  List.iter sem_decl d;
  List.iter sem_stmt s;
and sem_decl = function
  | D_var (v, l) -> add_variables v l 
  | D_fun (r, n, p) -> add_declaration r n p
  | D_fdef (r, n, p, b) -> add_declaration r n p; sem_body b

let sem_analysis t = 
  initSymbolTable 256;
  openScope ();
  List.iter sem_decl t;
  closeScope ();
