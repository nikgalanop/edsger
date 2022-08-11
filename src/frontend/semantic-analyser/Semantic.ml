open Ast
open Identifier
open Symbol 
open Types

let primitive_sem = function 
  | INT -> TYPE_int 
  | CHAR -> TYPE_char
  | BOOL -> TYPE_bool 
  | DOUBLE -> TYPE_double 

let rec str_of_type = function 
  | TYPE_none -> "none"
  | TYPE_int -> "int"
  | TYPE_bool -> "bool"
  | TYPE_char -> "char"
  | TYPE_double -> "double"
  | TYPE_pointer { typ = t; dim = d; mut = m } -> (str_of_type t) ^ String.make d '*'      
  | TYPE_null -> "null"
  | TYPE_proc -> "void"

let id_of_func n p = 
  id_make @@ "fun_" ^ n (* ^ "_" ^ string_of_params p *) (* TODO: Currently ignores overloading. *)
let id_of_var n = 
  id_make @@ "var_" ^ n
let id_of_label l = 
  id_make @@ "label_" ^ l

let check_jmp = function 
  | Some l -> begin 
        let id = id_of_label l in 
        try
          ignore @@ lookupEntry id LOOKUP_ALL_SCOPES true;
          true
        with Exit -> false
      end
  | None -> true
   
let is_null = function 
  | E_NULL -> true 
  | _ -> false
let is_mut = function 
  | TYPE_pointer r -> r.mut 
  | _ -> true
let is_lval = function
  | E_var _ | E_uop (O_dref, _) | E_arracc (_, _) -> true 
  | _ -> false  
let is_ptr = function 
  | TYPE_pointer _ -> true 
  | _ -> false
let is_assignable t e = 
  (not @@ is_null e) && is_mut t && is_lval e 

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
  | TYPE_int | TYPE_double | TYPE_bool | TYPE_pointer _ -> TYPE_bool
  | _ -> failwith "Cannot compare values with the provided type." 

let sem_uop t = function 
  | O_ref -> begin 
        match t with 
        | TYPE_pointer r ->
             TYPE_pointer { r with dim = r.dim + 1; mut = true } 
        | _ -> TYPE_pointer { typ = t; dim = 1; mut = true }
      end
  | O_dref -> begin 
        match t with
        | TYPE_pointer r
          when (r.dim > 0) -> 
            if (r.dim = 1) then r.typ 
            else TYPE_pointer { r with dim = r.dim - 1; mut = true } 
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
  | O_eq -> if (equalType t1 t2) then TYPE_bool
      else failwith "Cannot apply '==' on operands of different type." 
  | O_neq -> if (equalType t1 t2) then TYPE_bool 
      else failwith "Cannot apply '!=' on operands of different type."
  | O_and -> if (equalType t1 t2 && equalType t1 TYPE_bool) then TYPE_bool
      else failwith "Cannot apply 'and' on non-booleans."
  | O_or -> if (equalType t1 t2 && equalType t1 TYPE_bool) then TYPE_bool
      else failwith "Cannot apply 'or' on non-booleans."
  | O_comma -> t2
let sem_uasgn t = 
  match t with 
  | TYPE_int | TYPE_double | TYPE_pointer _ -> t
  | _ -> failwith "Cannot increment/decrement a non-numerical value or a non-pointer."
let sem_basgn t1 t2 = function 
  | O_asgn -> if (equalType t1 t2) then t1
      else failwith "Tried an assignment with values of different types."
  | O_mulasgn | O_divasgn -> if (equalType t1 t2) then sem_mul t1
      else failwith "Cannot multiply/divide values with different types."
  | O_modasgn -> if (equalType t1 t2 && equalType t1 TYPE_int) then t1 
      else failwith "Cannot compute 'mod' if operands are not both integers."
  | O_plasgn | O_minasgn -> sem_plus t1 t2   

let rec accept_parameters entrs ps = 
  match (entrs, ps) with 
  | (ent :: tl1, p :: tl2) -> if (accept_parameter ent p) then 
        accept_parameters tl1 tl2 else false    
  | [], [] -> true            
  | _ -> false 
and accept_parameter ent p = 
  match ent.entry_info with 
  | ENTRY_parameter inf -> let m = inf.parameter_mode in
        let t1 = inf.parameter_type in 
        let t2 = sem_expr p in 
        let et = equalType t1 t2 in 
        et && (m = PASS_BY_VALUE || is_assignable t2 p)
  | _ -> failwith "Should not find a non-parameter inside a paramlist."
and add_variables vt l = 
  Printf.printf "--- Variables:\n ";
  let add_variable var = 
    let (n, e) = var in
    let vtype = vartype_sem vt e in 
    Printf.printf "%s " n;
    ignore @@ newVariable (id_of_var n) vtype true
  in List.iter add_variable l; Printf.printf "\n"
and add_parameters f ps = (* Exception Handling? *)
  let add_parameter p = 
    let insert_param par mode = 
      let typ = vartype_sem (fst par) None in 
      let id = id_of_var (snd par) in 
      Printf.printf "%s " (snd par);
      ignore @@ newParameter id typ mode f true
    in match p with 
    | BYREF (t, i) -> insert_param (t, i) PASS_BY_REFERENCE
    | BYVAL (t, i) -> insert_param (t, i) PASS_BY_VALUE
  in List.iter add_parameter ps
and add_declaration r n p = (* Exception Handling? *)
   let f_id = id_of_func n p in
   let f, found = newFunction f_id in
   forwardFunction f;
   match f.entry_info with 
   | ENTRY_function inf -> begin
          let ft = (ftype_sem r) in
          Printf.printf "-- Inside the declaration of the function: %s %s.\n" (str_of_type ft) n;
          if (found) then begin
              if (not @@ equalType inf.function_result ft) then 
                failwith "Cannot overload functions with different return types but same parameters."
          end;
          begin
              Printf.printf "--- Parameters: ";
              openScope ();
              add_parameters f p; 
              endFunctionHeader f ft;
              closeScope ();
              Printf.printf "\n-- Outside the declaration of the function: %s %s.\n" (str_of_type ft) n
          end
      end
    | _ -> failwith "Should not find an entry that is not a function, with a label of a function."  
and add_definition r n p b = 
  let f_id = id_of_func n p in
  let f, found = newFunction f_id in
  match f.entry_info with 
  | ENTRY_function inf -> begin 
          let ft = (ftype_sem r) in
          Printf.printf "-- Inside the definition of the function: %s %s.\n" (str_of_type ft) n;
          if (found) then begin (* If found, then it is either declared or defined. *)
            let def = inf.function_pstatus = PARDEF_COMPLETE in (* If "defined". *)
            let frt = inf.function_result in
            if (not @@ equalType frt ft) then
                failwith "Cannot overload functions with the same parameters but different return type."
            else if (def) then 
                failwith "Cannot redefine the same function in the same scope."
          end;
          begin
             openScope ();
             Printf.printf "--- Parameters: ";
             add_parameters f p;  
             endFunctionHeader f ft;
             Printf.printf "\n--- Body of the function.\n";
             sem_body ft b;  
             closeScope ();
             Printf.printf "--- End of body.\n";
             Printf.printf "-- Outside the definition of the function: %s %s.\n"   (str_of_type ft) n
          end
        end
    | _ -> failwith "Should not find an entry that is not a function, with a label of a function."
and vartype_sem t e = 
  let PTR (p, i) = t in 
  let pt = primitive_sem p in
  match (e, i) with 
  | None, 0 -> pt 
  | None, i -> TYPE_pointer { typ = pt;
      dim = i; mut = true }
  | Some x, i -> let t = sem_expr x in 
      if (equalType t TYPE_int) then TYPE_pointer { typ = pt; 
        dim = i + 1; mut = i = 0 }
      else failwith "Cannot declare an array with a non-integer length."   
and ftype_sem = function 
  | VOID -> TYPE_proc
  | RET vt -> vartype_sem vt None
and sem_expr = function
  | E_var s -> 
      begin 
        try 
          let entry = lookupEntry (id_of_var s) LOOKUP_ALL_SCOPES false in
          match entry.entry_info with 
          | ENTRY_variable i -> i.variable_type
          | ENTRY_parameter i -> i.parameter_type
          | _ -> let msg = Printf.sprintf "'%s' is not a variable." s in 
              failwith msg
        with Not_found -> let msg = Printf.sprintf "Variable '%s' does not exist." s in
              failwith msg
      end
  | E_int _ -> TYPE_int
  | E_char _ -> TYPE_char
  | E_double _ -> TYPE_double
  | E_str _ -> TYPE_pointer { typ = TYPE_char; 
      dim = 1; mut = false }
  | E_bool _ -> TYPE_bool
  | E_NULL -> TYPE_null
  | E_uop (op, e) -> let t = sem_expr e in 
      sem_uop t op 
  | E_binop (e1, op, e2) -> let t1 = sem_expr e1 in 
      let t2 = sem_expr e2 in sem_binop t1 t2 op
  | E_uasgnpre (ua, e) | E_uasgnpost (ua, e) -> let t = sem_expr e in 
      if (is_assignable t e) then sem_uasgn t 
      else failwith "Tried to increment/decrement something non-assignable."
  | E_basgn (e1, op, e2) -> let t1 = sem_expr e1 in 
      if (is_assignable t1 e1) then let t2 = sem_expr e2 in sem_basgn t1 t2 op
      else failwith "Tried to assign a value to something non-assignable."  
  | E_tcast (v, e) -> ignore @@ sem_expr e; 
      let t1 = vartype_sem v None in t1
  | E_ternary (e1, e2, e3) -> let t1 = sem_expr e1 in 
      let t2 = sem_expr e2 in let t3 = sem_expr e3 in 
      if (equalType t1 TYPE_bool) then 
        if (equalType t2 t3) then t2  
        else failwith "Return values of ternary statement do not have the same type." 
      else failwith "Non-boolean condition in ternary statement."
  | E_new (v, e) ->  let t1 = sem_expr e in 
        if (equalType t1 TYPE_int) then
          let t2 = vartype_sem v None in 
          match t2 with 
          | TYPE_pointer r when r.mut -> 
              TYPE_pointer { r with dim = r.dim + 1 }
          | TYPE_pointer r -> failwith "Cannot allocate memory of type 'static array'."
          | t -> TYPE_pointer { typ = t; dim = 1; mut = true }
        else failwith "Cannot allocate an array of non-integer length." 
  | E_delete (e) -> let t = sem_expr e in 
      if (is_ptr t) then match t with 
        | TYPE_pointer r when r.mut -> 
            TYPE_pointer r
        | _ -> failwith "Tried to deallocate a statically allocated array."
      else failwith "Tried to deallocate memory using a non-pointer."
  | E_fcall (f, l) -> let fid = id_of_func f () in begin
        try 
          let e = lookupEntry fid LOOKUP_ALL_SCOPES true in 
          let match_func ent =
              match ent.entry_info with 
              | ENTRY_function inf -> let plst = inf.function_paramlist in 
                    accept_parameters plst l
              | _ -> failwith "Should not find a non-function that has an identifier of a function."
          in 
          if (not @@ match_func e) then
            let msg = Printf.sprintf "No definitions/declarations of '%s' match with the provided values." f in
            failwith msg
          else match e.entry_info with 
          | ENTRY_function inf -> inf.function_result
          | _ -> failwith "Should not reach this state." 
        with Exit -> let msg = Printf.sprintf "Called a non-existing function: %s.\n" f in 
              failwith msg
      end
      (* TODO: For the time being, ignores overloading. *) 
  | E_arracc (e1, e2) -> let t1 = sem_expr e1 in
      if (is_ptr t1) then 
        let t2 = sem_expr e2 in 
        if (equalType t2 TYPE_int) then 
            match t1 with 
            | TYPE_pointer { typ = t; dim = 1; mut = _ } -> t 
            | TYPE_pointer r ->TYPE_pointer { r with dim = r.dim - 1; mut = true }
            | _ -> failwith "A value that is not a pointer should not have the type of a pointer."  
        else failwith "The index of an array element must be an integer."
      else failwith "Tried to access an indexed position of a non-array."
  | E_brack (e) -> sem_expr e
and check_condition c = 
  let t = sem_expr c in 
  if (equalType t TYPE_bool) then ()
  else failwith "The condition of a control statement must be a boolean value."
and check_option = function 
  | Some e -> ignore @@ sem_expr e 
  | _ -> ()      
and sem_for ft s = function 
  | Some l -> let l_id = (id_of_label l) in
      ignore @@ newLabel l_id true;
      openForScope (); sem_stmt ft s; closeForScope (Some l_id)
  | None -> openForScope (); sem_stmt ft s; closeForScope None
and sem_stmt ft = function 
  | S_NOP -> ()
  | S_expr e -> ignore @@ sem_expr e
  | S_block b -> List.iter (sem_stmt ft) b
  | S_if (e, s, None) -> check_condition e; 
      sem_stmt ft s
  | S_if (e, s1, Some s2) -> check_condition e; 
      sem_stmt ft s1; sem_stmt ft s2
  | S_for (o1, Some c, o3, s, l) -> check_option o1; 
      check_condition c; check_option o3; sem_for ft s l
  | S_for (_, None, _, _, _) -> failwith "For-loops should always have a terminating condition."
  | S_cont l -> if (insideFor ()) then  
        if (check_jmp l) then () 
        else failwith "Cannot continue to an unreachable label." 
      else failwith "Cannot continue when not inside a for statement."  
  | S_break l -> if (insideFor ()) then  
        if (check_jmp l) then () 
        else failwith "Cannot break and jump to an unreachable label."
      else failwith "Cannot break when not inside a for statement." 
  | S_ret None -> if (equalType ft TYPE_proc) then () 
      else failwith "Must return a value that matches the function's return type."
  | S_ret Some e -> let t = sem_expr e in 
      if (equalType ft t) then () 
      else failwith "Must return a value that matches the function's return type."
and sem_body ft b = 
  let F_body (d, s) = b in
  List.iter sem_decl d;
  List.iter (sem_stmt ft) s
and sem_decl = function
  | D_var (v, l) -> add_variables v l 
  | D_fun (r, n, p) -> begin 
        try add_declaration r n p with 
        | Failure msg -> Utilities.fail_sem msg (Utilities.FDecl n) 
        | e -> Utilities.fail_sem ((Printexc.to_string e)) (Utilities.FDef n) 
      end
  | D_fdef (r, n, p, b) -> begin 
        try add_definition r n p b with 
        | Failure msg -> Utilities.fail_sem msg (Utilities.FDef n) 
        | e -> Utilities.fail_sem ((Printexc.to_string e)) (Utilities.FDef n) 
      end

let sem_analysis t = 
  Printf.printf "\027[1;36mSemantic Analysis:\027[0m \n";
  initSymbolTable 256;
  List.iter sem_decl t;
