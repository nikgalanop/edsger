open Ast
open Symbol 
open Identifier
open Types
open SemUtilities

exception SemFailure of Lexing.position * string

let sem_fail pos msg = raise (SemFailure (pos, msg))

let sem_mul pos t = 
  if (equalType t TYPE_int || equalType t TYPE_double) then t
  else sem_fail pos "Cannot multiply/divide non-arithmetic values"
let sem_plus pos t1 t2 = 
  match t2 with
  | TYPE_int -> begin
      match t1 with 
      | TYPE_int | TYPE_null | TYPE_pointer _ -> t1 
      | _ -> sem_fail pos "Can only add an integer to an integer or a pointer"
    end
  | TYPE_double -> if (equalType t1 t2) then t1 
    else sem_fail pos "Can only add/subtract a double to a double"
  | _ -> sem_fail pos "Cannot add to/subtract from something with a non-arithmetic value"
let sem_comp pos t = 
  match t with 
  | TYPE_int | TYPE_double | TYPE_null | TYPE_bool | TYPE_pointer _ -> TYPE_bool
  | _ -> sem_fail pos "Cannot compare values with the provided type" 

let sem_uop pos e t = function 
  | O_ref -> begin 
    if (not @@ is_lval e) then sem_fail pos "Expected to refer to an l-value";
    match t with 
    | TYPE_pointer r ->
      TYPE_pointer { r with dim = r.dim + 1; mut = true } 
    | _ -> TYPE_pointer { typ = t; dim = 1; mut = true }
    end
  | O_dref -> begin
    match t with
    | TYPE_pointer r when (r.dim > 0) -> 
      if (r.dim = 1) then r.typ 
      else TYPE_pointer { r with dim = r.dim - 1; mut = true } 
    | TYPE_null -> sem_fail pos "Tried to dereference a null-pointer"
    | _ -> sem_fail pos "Tried to dereference a non-pointer"
    end
  | O_psgn -> if (equalType t TYPE_int || equalType t TYPE_double) then t
    else sem_fail pos "Cannot specify sign of non-arithmetic value"
  | O_nsgn -> if (equalType t TYPE_int || equalType t TYPE_double) then t
    else sem_fail pos "Cannot specify sign of non-arithmetic value"
  | O_neg -> if (equalType t TYPE_bool) then t 
    else sem_fail pos "Cannot negate a non-boolean"
let sem_binop pos t1 t2 = function
  | O_times | O_div -> if (equalType t1 t2) then sem_mul pos t1
    else sem_fail pos "Cannot multiply/divide values with different types"
  | O_mod -> if (equalType t1 t2 && equalType t1 TYPE_int) then t1 
    else sem_fail pos "Cannot compute `mod` if operands are not both integers"
  | O_plus | O_minus -> sem_plus pos t1 t2
  | O_lt | O_gt | O_le | O_ge -> if (equalType t1 t2) then sem_comp pos t1  
    else sem_fail pos "Can only compare values of the same type"
  | O_eq -> if (equalType t1 t2) then TYPE_bool
    else sem_fail pos "Cannot apply `==` on operands of different type" 
  | O_neq -> if (equalType t1 t2) then TYPE_bool 
    else sem_fail pos "Cannot apply `!=` on operands of different type"
  | O_and -> if (equalType t1 t2 && equalType t1 TYPE_bool) then TYPE_bool
    else sem_fail pos "Cannot apply `and` on non-booleans"
  | O_or -> if (equalType t1 t2 && equalType t1 TYPE_bool) then TYPE_bool
    else sem_fail pos "Cannot apply `or` on non-booleans"
  | O_comma -> t2
let sem_uasgn pos t = 
  match t with 
  | TYPE_int | TYPE_double | TYPE_pointer _ -> t
  | _ -> sem_fail pos "Cannot increment/decrement a non-arithmetic value or a non-pointer"
let sem_basgn pos t1 t2 = function 
  | O_asgn -> if (equalType t1 t2) then t1
    else sem_fail pos "Tried an assignment with values of different types"
  | O_mulasgn | O_divasgn -> if (equalType t1 t2) then sem_mul pos t1
    else sem_fail pos "Cannot multiply/divide values with different types"
  | O_modasgn -> if (equalType t1 t2 && equalType t1 TYPE_int) then t1 
    else sem_fail pos "Cannot compute `mod` if operands are not both integers"
  | O_plasgn | O_minasgn -> sem_plus pos t1 t2   

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
    let t2 = snd p in 
    let et = equalType t1 t2 in 
    et && (m = PASS_BY_VALUE || is_assignable t2 (fst p))
  | _ -> 
    failwith "Should not find a non-parameter inside a paramlist"
and add_variables pos vt l = 
  let add_variable var = 
    let (n, e) = var in
    let vtype = vartype_sem vt e in 
    try
      ignore @@ newVariable (id_of_var n) vtype true
    with | Failure msg -> sem_fail pos msg
  in List.iter add_variable l; 
and add_parameters pos f ps =  
  let info = match f.entry_info with 
  | ENTRY_function inf -> inf
  | _ -> failwith "Should not find a non-function"
  in let def = info.function_pstatus = PARDEF_COMPLETE in
  let ft = info.function_result in 
  let pf = info.function_paramlist in
  let n = ent_name_of_id f.entry_id in
  let add_parameter p = 
    let insert_param par mode = 
      let typ = vartype_sem (fst par) None in 
      let id = id_of_var (snd par) in 
      try
        ignore @@ newParameter id typ mode f true
      with | Failure m -> let msg = if def then m
        else Printf.sprintf "%s while trying to overload `%s` with `%s`"
          m (header_of_astf ft n ps) (header_of_symbolf ft n pf) 
        in sem_fail pos msg 
    in match p with 
    | BYREF (t, i) -> insert_param (t, i) PASS_BY_REFERENCE
    | BYVAL (t, i) -> insert_param (t, i) PASS_BY_VALUE
  in List.iter add_parameter ps
and add_declaration pos r n p =
   let p_str = name_mangling p in
   let f_id = id_of_func n p_str in
   let f, found = newFunction f_id in
   forwardFunction f;
   match f.entry_info with 
   | ENTRY_function inf -> begin
        let ft = (ftype_sem r) in
        let ps = inf.function_paramlist in
        if (found) then begin 
          let def = inf.function_pstatus = PARDEF_COMPLETE in
          let frt = inf.function_result in
          if (not @@ equalType frt ft) then begin
            let msg = Printf.sprintf "Cannot overload the function `%s` with a function \
              of a different return type, but same-type parameters, `%s`" 
              (header_of_symbolf frt n ps) (header_of_astf ft n p) in 
            sem_fail pos msg
          end;
          if (def) then begin
            let msg = Printf.sprintf "Cannot declare the function `%s` when `%s` \
              is already defined in the same scope" 
              (header_of_astf ft n p) (header_of_symbolf ft n ps)  in 
            sem_fail pos msg
          end;
        end; 
        begin
          openScope ();
          add_parameters pos f p; 
          endFunctionHeader f ft;
          closeScope ();
        end
      end
    | _ -> 
      failwith "Should not find an entry that is not a function, with a label of a function"  
and add_definition pos r =
  let p_str = name_mangling r.p in
  let f_id = id_of_func r.fn p_str in
  let f, found = newFunction f_id in
  match f.entry_info with 
  | ENTRY_function inf -> begin 
      let ft = (ftype_sem r.rt) in
      let ps = inf.function_paramlist in
      if (found) then begin
        let def = inf.function_pstatus = PARDEF_COMPLETE in
        let frt = inf.function_result in
        if (not @@ equalType frt ft) then begin
          let msg = Printf.sprintf "Cannot overload the function `%s` with a function \
            of a different return type, but same type parameters, `%s`" 
            (header_of_symbolf frt r.fn ps) (header_of_astf ft r.fn r.p) in 
          sem_fail pos msg
        end;
        if (def) then begin
          let msg = Printf.sprintf "Cannot define the function `%s` in the same scope with `%s`"
          (header_of_astf ft r.fn r.p) (header_of_symbolf ft r.fn ps) in
          sem_fail pos msg
        end; 
      end;
      begin 
        openScope ();
        openEnv ();
        add_parameters pos f r.p;  
        endFunctionHeader f ft;
        sem_body ft r.b;
        closeScope (); (* This call MUST be before the closeEnv call. *)
        let store_env entryenv = 
          let entry_to_param e = 
            let name = ent_name_of_id e.entry_id in 
            let type' = ast_vartype_of_typ @@ 
            match e.entry_info with   
            | ENTRY_variable inf  -> inf.variable_type 
            | ENTRY_parameter inf -> inf.parameter_type 
            | _ -> failwith "Stored an invalid entry as an env. variable."
            in BYREF(type', name)
          in r.env <- List.map entry_to_param entryenv;
        in begin match closeEnv () with 
        | None -> ()
        | Some env -> store_env env
        end;
      end
    end
  | _ -> 
    failwith "Should not find an entry that is not a function, with a label of a function"
and vartype_sem t e = 
  let PTR (p, i) = t in 
  let pt = typ_of_primitive p in
  match (e, i) with 
  | None, 0 -> pt 
  | None, i -> TYPE_pointer { typ = pt;
    dim = i; mut = true }
  | Some x, i -> let t = sem_expr x in 
    if (equalType t TYPE_int) then 
      if (is_const x) then TYPE_pointer { typ = pt; dim = i + 1; mut = false }
      else sem_fail x.meta "Cannot declare a static array with a non-constant length"
    else sem_fail x.meta "Cannot declare a static array with a non-integer length"   
and ftype_sem = function 
  | VOID -> TYPE_proc
  | RET vt -> vartype_sem vt None
and sem_expr exp = 
  let pos = exp.meta in
  match exp.expr with 
  | E_var s -> begin try 
      let entr = lookupEntry (id_of_var s) LOOKUP_ALL_SCOPES false in
      let res = match entr.entry_info with 
      | ENTRY_variable i -> i.variable_type
      | ENTRY_parameter i -> i.parameter_type
      | _ -> let msg = Printf.sprintf "`%s` is not a variable" s in 
          sem_fail pos msg
      in pushToCurrentEnv entr; res
    with Not_found -> let msg = Printf.sprintf "Variable `%s` does \
      not exist" s in sem_fail pos msg
    end
  | E_int _ -> TYPE_int
  | E_char _ -> TYPE_char
  | E_double _ -> TYPE_double
  | E_str _ -> TYPE_pointer { typ = TYPE_char; 
    dim = 1; mut = false }
  | E_bool _ -> TYPE_bool
  | E_NULL -> TYPE_null
  | E_uop (op, e) -> let t = sem_expr e in 
    sem_uop pos e t op 
  | E_binop (e1, op, e2) -> let t1 = sem_expr e1 in 
    let t2 = sem_expr e2 in sem_binop pos t1 t2 op
  | E_uasgnpre (ua, e) | E_uasgnpost (ua, e) -> let t = sem_expr e in 
    if (is_assignable t e) then sem_uasgn pos t 
    else sem_fail pos "Tried to increment/decrement something non-assignable"
  | E_basgn (e1, op, e2) -> let t1 = sem_expr e1 in
    if (is_assignable t1 e1) then let t2 = sem_expr e2 in sem_basgn pos t1 t2 op
    else sem_fail pos "Tried to assign a value to something non-assignable"  
  | E_tcast (v, e) -> let t1 = sem_expr e in
    let t2 = vartype_sem v None in
    if (valid_cast t1 t2) then t2 
    else let msg = Printf.sprintf "Invalid type conversion from %s to %s" 
      (str_of_type ~short:false ~ptr_format:true t1) (str_of_type ~short:false ~ptr_format:true t2)
    in sem_fail pos msg
  | E_ternary (e1, e2, e3) -> let t1 = sem_expr e1 in 
    let t2 = sem_expr e2 in let t3 = sem_expr e3 in 
    if (equalType t1 TYPE_bool) then
      if (equalType t2 t3) then t2  
      else sem_fail e2.meta "Return values of ternary statement do not have the same type" 
    else sem_fail pos "Non-boolean condition in ternary statement"
  | E_new (v, e) ->  let t1 = sem_expr e in 
    if (equalType t1 TYPE_int) then
      let t2 = vartype_sem v None in 
      match t2 with 
      | TYPE_pointer r when r.mut -> 
        TYPE_pointer { r with dim = r.dim + 1 }
      | TYPE_pointer r -> sem_fail pos "Cannot allocate memory of type `static array`"
      | t -> TYPE_pointer { typ = t; dim = 1; mut = true }
    else sem_fail pos "Cannot allocate an array of non-integer length" 
  | E_delete e -> let t = sem_expr e in 
    if (is_ptr t) then match t with 
      | TYPE_pointer r when r.mut -> 
        TYPE_none
      | _ -> sem_fail pos "Tried to deallocate a statically allocated array"
    else sem_fail pos "Tried to deallocate memory using a non-pointer"
  | E_fcall r -> let p_types = List.map sem_expr r.exprs in
    let p_str = str_of_fval_types p_types in
    let fid = id_of_func r.fn p_str in begin
    try 
      let e = lookupEntry fid LOOKUP_ALL_SCOPES true in 
      let match_func ent =
        match ent.entry_info with 
        | ENTRY_function inf -> let plst = inf.function_paramlist in 
          accept_parameters plst (List.combine r.exprs p_types)
        | _ -> failwith "Should not find a non-function that has an identifier of a function"
      in 
      if (not @@ match_func e) then
        let msg = Printf.sprintf "No definitions/declarations of `%s` \
          match with the provided values" r.fn in sem_fail pos msg
      else match e.entry_info with 
        | ENTRY_function inf -> let scp = inf.function_number in 
          r.mangl <- id_name fid;
          inf.function_result
        | _ -> failwith "Should not reach this state" 
    with Exit -> let msg = Printf.sprintf "Called a non-existing \
        function `%s`" (str_of_fcall r.fn p_types) 
      in sem_fail pos msg
    end
  | E_arracc (e1, e2) -> let t1 = sem_expr e1 in
    if (is_ptr t1) then 
      let t2 = sem_expr e2 in 
      if (equalType t2 TYPE_int) then 
        match t1 with 
        | TYPE_pointer { typ = t; dim = 1; mut = _ } -> t 
        | TYPE_pointer r -> TYPE_pointer { r with dim = r.dim - 1; mut = true }
        | _ -> sem_fail pos "A value that is not a pointer should not have the type of a pointer"  
      else sem_fail pos "The index of an array element must be an integer"
    else sem_fail pos "Tried to access an indexed position of a non-array"
  | E_brack (e) -> sem_expr e
and check_condition c = 
  let t = sem_expr c in 
  if (equalType t TYPE_bool) then ()
  else sem_fail c.meta "The condition of a control statement must be a boolean value"
and check_option = function 
  | Some e -> ignore @@ sem_expr e 
  | _ -> ()      
and sem_for pos ft s = function 
  | Some l -> let l_id = (id_of_label l) in
    begin try
      ignore @@ newLabel l_id true;
      openForScope (); sem_stmt ft s; 
      closeForScope (Some l_id)
    with | Failure _ -> 
      let msg = Printf.sprintf "Should not find two labels with the same name (`%s`) \
        inside the same function" l in
      sem_fail pos msg
    end
  | None -> openForScope (); sem_stmt ft s; closeForScope None
and sem_stmt ft (stm : ast_stmt) = 
  let pos = stm.meta in
  match stm.stmt with 
  | S_NOP -> ()
  | S_expr e -> ignore @@ sem_expr e
  | S_block b -> List.iter (sem_stmt ft) b
  | S_if (e, s1, o) -> begin match o with 
      | None -> check_condition e; 
        sem_stmt ft s1
      | Some s2 -> check_condition e; 
        sem_stmt ft s1; sem_stmt ft s2
    end
  | S_for (o1, o2, o3, s, l) -> begin match o2 with 
      | Some c -> check_option o1; check_condition c; 
        check_option o3; sem_for pos ft s l
      | _ -> 
        sem_fail pos "For-loops should always have a terminating condition"
    end
  | S_cont l -> if (insideFor ()) then 
      if (check_jmp l) then () 
      else sem_fail pos "Cannot continue to an unreachable label" 
    else sem_fail pos "Cannot continue when not inside a for statement"  
  | S_break l -> if (insideFor ()) then  
      if (check_jmp l) then () 
      else sem_fail pos "Cannot break and jump to an unreachable label"
    else sem_fail pos "Cannot break when not inside a for statement" 
  | S_ret o -> begin match o with 
      | Some e -> let t = sem_expr e in 
        if (equalType ft t) then () 
        else sem_fail pos "Must return a value that matches the function's return type"
      | None -> if (equalType ft TYPE_proc) then () 
        else sem_fail pos "Must return a value that matches the function's return type"
    end 
and sem_body ft b = 
  let F_body (d, s) = b in
  List.iter sem_decl d;
  List.iter (sem_stmt ft) s
and sem_decl (dec : ast_decl) = 
  let pos = dec.meta in 
  match dec.decl with
  | D_var (v, l) -> add_variables pos v l 
  | D_fun (rt, fn, ps) -> add_declaration pos rt fn ps 
  | D_fdef r -> add_definition pos r

let sem_analysis t = 
  initSymbolTable 256;
  List.iter sem_decl t;
  exists_main ();