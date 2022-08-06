open Ast
open Identifier
open Symbol 
open Types

let primitive_sem = function 
  | INT -> TYPE_int 
  | CHAR -> TYPE_char
  | BOOL -> TYPE_bool 
  | DOUBLE -> TYPE_double 
let vartype_sem t e = 
  let PTR (p, i) = t in 
  let pt = primitive_sem p in
  match (e, i) with 
  | None, 0 -> pt 
  | None, i when i > 0 -> TYPE_pointer { typ = pt;
      dim = i; mut = true }
  | Some x, i -> TYPE_pointer {typ = pt; 
      dim = i + 1; mut = i = 0} (* TODO: Should add a check for the
                                  "validity" of expression x. *)

let add_variables vt l = 
  let add_variable var = 
    let (name, e) = var in
    let vtype = vartype_sem vt e in 
     newVariable (id_make name) vtype true
  in List.iter add_variable 

(* TODO *)
let add_declaration = ()

let is_lval = function  (* TODO: Maybe check the type of the E_var before considering it an lvalue? 
                          Eg. the *VAR* is not an immutable array. (Specification p. 8) *)
  | E_var _ | E_uop (O_dref, _) | E_arracc (_, _) -> true 
  | _ -> false  
let is_ptr = function 
  | TYPE_pointer _ -> true 
  | TYPE_null -> true
  | _ -> false

let sem_mul t = 
  if (equalType t TYPE_int || equalType t TYPE_double) then t
  else failwith "Cannot multiply/divide non-numerical values."
let sem_plus t1 t2 = 
  match t2 with
  | TYPE_int -> begin
        match t1 with 
        | TYPE_int | TYPE_pointer _ -> t1 
        | _ -> failwith "Can only add an integer to an integer or a pointer."
      end
  | TYPE_double -> if (equalType t1 t2) then t1 
      else failwith "Can only add/subtract a double to a double."
  | _ -> failwith "Cannot add/subtract to something with a non-numerical value."
let sem_comp t = 
  match t with 
  | TYPE_int | TYPE_double | TYPE_bool | TYPE_pointer _ -> t
  | _ -> failwith "Cannot compare values with the provided type." 

let sem_uop t = function 
  (* TODO: Take care of NULL & procs maybe. *)
  | O_ref -> begin 
        match t with 
        | TYPE_pointer r ->
             TYPE_pointer { r with dim = r.dim + 1 } 
          (* What to do with mutability when refing? *)
        | _ -> TYPE_pointer { typ = t; dim = d; mut = true } (* Reconsider mutability. *)
      end
  | O_dref -> begin 
        match t with
        | TYPE_pointer r
          when (r.dim > 0) -> if (r.dim = 1) then t 
              else { r with dim = r.dim - 1 } 
          (* What to do with mutability when derefing? *)
        | _ -> failwith "Tried to dereference a non-pointer."
      end
  | O_psgn -> if (equalType t TYPE_int || equalType t TYPE_double) then t
      else failwith "Cannot specify sign of non-numerical value."
  | O_nsgn -> if (equalType t TYPE_int || equalType t TYPE_double) then t
      else failwith "Cannot specify sign of non-numerical value."
  | O_neg -> if (equalType t TYPE_bool) then t 
      else failwith "Cannot negate a non-boolean."
let sem_binop t1 t2 = function
  | O_times | O_div -> if (equalType t1 t2) then sem_mul t1
      else failwith "Cannot multiply/divide values with different types."
  | O_mod -> if (equalType t1 t2 && equalType t1 TYPE_int) then t1 
      else failwith "Cannot compute 'mod' if operands are not both integers."
  | O_plus | O_minus -> sem_plus t1 t2
  | O_lt | O_gt | O_le | O_ge -> if (equalType t1 t2) then sem_comp t1  
      else failwith "Can only compare values of the same type."
  | O_eq -> if (equalType t1 t2) then t1 
      else failwith "Cannot apply '==' on operands of different type." 
  | O_neq -> if (equalType t1 t2) then t1 
      else failwith "Cannot apply '!=' on operands of different type."
  | O_and -> if (equalType t1 t2 && equalType t1 TYPE_bool) then t1 
      else failwith "Cannot apply 'and' on non-booleans."
  | O_or -> if (equalType t1 t2 && equalType t1 TYPE_bool) then t1 
      else failwith "Cannot apply 'or' on non-booleans."
  | O_comma -> t2
let sem_uasgn t = 
  match t with 
  | TYPE_int | TYPE_double | TYPE_pointer _ -> t
  | _ -> failwith "Cannot increment/decrement a non-numerical value or a non-pointer."
let sem_basgn t1 t2 = function 
  | O_asgn -> if (equalTypes t1 t2) then t1
      else failwith "Tried an assignment with values of different types."
  | O_mulasgn | O_divasgn -> if (equalType t1 t2) then sem_mul t1 t2
      else failwith "Cannot multiply/divide values with different types."
  | O_modasgn -> if (equalType t1 t2 && equalType t1 TYPE_int) then t1 
      else failwith "Cannot compute 'mod' if operands are not both integers."
  | O_plasgn | O_minasgn -> sem_plus t1 t2   

(* IMPORTANT CONSIDERATION: IN ASSIGNMENTS WE MUST CHECK WHETHER OR NOT THE LHS IS AN L-VALUE. *)
(* Something that I am not 100% if it's completely implemented. *)

(* IMPORTANT CONSIDERATION: MAKE SURE THAT NULL CAN BE ASSIGNED TO A POINTER OF ANY TYPE. *)

let rec sem_expr = function
  | E_var s -> 
      let entry = lookupEntry (id_make s) LOOKUP_ALL_SCOPES false in
      begin
        match entry.entry_info with 
        | ENTRY_variable i -> i.variable_type
        | ENTRY_parameter i -> i.parameter_type
        | ENTRY_temporary i -> i.temporary_type
        | _ -> failwith @@ s ^ " is not a variable."
      end
                (* TODO: Do not quite understand the analysis I must do here. *)
  | E_int _ -> TYPE_int
  | E_char _ -> TYPE_char
  | E_double _ -> TYPE_double
  | E_str _ -> TYPE_pointer { typ = TYPE_char; 
      dim = 1; mut = false}
  | E_bool _ -> TYPE_bool
  | E_NULL -> TYPE_null (* We need a TYPE_null unfortunately. *)
  | E_uop (op, e) -> let t = sem_expr e in 
      sem_uop t op (* &, *, !, +, - *)
  | E_binop (e1, op, e2) -> let t1 = sem_expr e1 in 
      let t2 = sem_expr e2 in sem_binop t1 t2 op
  | E_uasgnpre (ua, e) | E_uasgnpost (ua, e) -> let t = sem_expr e in 
      if (is_lval e) then sem_uasgn t (* First check if the expr e is valid. *)
      else failwith "Tried to increment/decrement something non-assignable."
  | E_basgn (e1, op, e2) -> let t1 = sem_expr e1 in 
      if (is_lval e1) then let t2 = sem_expr e2 in sem_basgn t1 t2 op
      else "Tried to assign a value to something non-assignable."  
  | E_tcast (v, e) -> let t = sem_expr e in 
      TYPE_none  (* TODO. What is going on with typecasting? :D 
                    https://en.cppreference.com/w/c/language/cast *)
  | E_ternary (e1, e2, e3) -> let t1 = sem_expr e1 in 
      let t2 = sem_expr e2 in let t3 = sem_expr e3 in 
      if (equalType t1 TYPE_bool) then 
        if (equalType t2 t3) then t2  
        else failwith "Return values of ternary statement do not have the same type." 
      else failwith "Non-boolean condition in ternary statement."
  | E_new (v, e) ->  let t1 = sem_expr e in 
      if (equalType t1 TYPE_int) then 
        let t2 = sem_expr v in 
        if (is_ptr t2) then match t2 with 
          | TYPE_pointer r when r.mut -> 
              TYPE_pointer { r with dim = r.dim + 1 }
          | _ -> failwith "Tried to allocate memory by using an immutable pointer."
        else failwith "Tried to deallocate memory using a non-pointer."
      else failwith "Cannot allocate an array of non-integer dimension." 
  | E_delete (e) -> let t = sem_expr e in 
      if (is_ptr t) then match t with 
        | TYPE_pointer r when r.mut -> 
            TYPE_pointer { r with dim = r.dim + 1 }
        | _ -> failwith "Tried to deallocate a statically allocated array."
      else failwith "Tried to deallocate memory using a non-pointer."
  (* TODO: Should make sure that the pointer of e, actually points somewhere and not in a NULL value. *)
  | E_fcall (f, l) -> TYPE_none 
  (* TODO: Check existance of function and that the provided values match the parameters. *)
  (* ! ALSO CHECK THAT FOR BYREF PARAMETERS, WE PROVIDE MUTABLE VALUES. ! *)
  | E_arracc (e1, e2) -> let t1 = sem_expr e1 in
      if (is_ptr t1) then 
        let t2 = sem_expr e2 in 
        if (equalType t2 TYPE_int) then 
            match t1 with 
            | TYPE_pointer r when r.dim = 1 -> r.typ
            | TYPE_pointer r -> { r with dim = r.dim - 1 }  
        else failwith "The index of an array element must be an integer."
      else failwith "Tried to access an indexed position of a non array."
  | E_brack (e) -> sem_expr e
and check_condition c = 
  let t = sem_expr c in 
  if (equalType t TYPE_bool) then ()
  else failwith "The condition of a control statement must be a boolean value."
and check_option = function 
  | Some e -> ignore @@ sem_expr e 
  | _ -> ()
and sem_stmt = function 
  | S_NOP -> ()
  | S_expr e -> ignore @@ sem_expr e
  | S_block l -> List.iter sem_stmt s;
  | S_if (e, s, None) -> check_condition e; 
      sem_stmt s
  | S_if (e, s1, Some s2) -> check_condition e; 
      sem_stmt s1; sem_stmt s2
  | S_for (o1, Some c, o3, s, l) -> check_option o1; 
      check_condition c; check_option o3; sem_stmt s 
      (* Incomplete for sure. Have to add the label into the symbol table. *)
  | S_cont l -> () (* TODO: Should check that the label exists and that cont is inside the "scope" of the said label. *)
  | S_break l -> () (* TODO: Should check that the label exists and that cont is inside the "scope" of the said label. *)
  | S_ret None -> () (* TODO: The rettype of the function that contains this ret stmt must be void. *)
  | S_ret Some e -> () (* TODO: The rettype of the function that contains this ret stmt must be the same as the type of e. *)
and sem_body b = 
  let F_body (d, s) = b in
  List.iter sem_decl d;
  List.iter sem_stmt s;
and sem_decl = function
  | D_var (v, l) -> 
      try add_variables v l 
      with Failure_NewEntry _ -> failwith "Tried to redefine the same variable."
  | D_fun (r, n, p) -> add_declaration r n p
  | D_fdef (r, n, p, b) -> add_declaration r n p; sem_body b

let sem_analysis t = 
  initSymbolTable 256;
  openScope ();
  List.iter sem_decl t;
  closeScope ();