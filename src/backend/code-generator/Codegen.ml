open Ast
open Identifier
open CGSymbol
open Llvm

exception CGFailure of Lexing.position * string
let cg_fail pos msg = 
  raise (CGFailure (pos, msg))

let lcontext = global_context ()
let lmodule = create_module lcontext "edsger-program"
let lbuilder = builder lcontext
let int_type = i16_type lcontext
and char_type = i8_type lcontext
and bool_type = i1_type lcontext 
and double_type = double_type lcontext
let const_int' = const_int int_type 
and const_char' = const_int char_type
and const_bool' = const_int bool_type
and const_double' = const_float double_type

let const_pointer_null' vl = 
  const_null @@ element_type @@ type_of vl
let classify_type' vl = 
  classify_type @@ type_of vl
let classify_element_type ptr = 
  classify_type @@ element_type @@ type_of ptr

let lltype_of_primitive = function 
  | INT -> int_type
  | CHAR -> char_type
  | BOOL -> bool_type
  | DOUBLE -> double_type
let lltype_of_vartype t = 
  let PTR (pt, d) = t in
  let rec aux pt = function 
    | 0 -> lltype_of_primitive pt 
    | d -> pointer_type @@ aux pt (d - 1)
  in aux pt d 
let can_add_terminator () = 
  let tmp = block_terminator @@ 
    insertion_block lbuilder 
  in tmp = None
let lltype_of_rettype = function  
  | VOID -> void_type lcontext
  | RET vt -> lltype_of_vartype vt
let lltype_of_parameters ps =
  let lltype_of_parameter = function
    | BYREF (vt, _) -> 
      pointer_type @@ lltype_of_vartype vt
    | BYVAL (vt, _) -> lltype_of_vartype vt
  in ps |> List.map lltype_of_parameter |>
  Array.of_list
let function_type_of_header rt ps = 
  let llrt = lltype_of_rettype rt in 
  let prms = lltype_of_parameters ps in 
  function_type llrt prms
let build_edsger_cast vl tto = 
  let tfrom = type_of vl in 
  begin match classify_type tto with 
  | Llvm.TypeKind.Integer -> 
      if (tto = int_type) then 
        begin match classify_type tfrom with 
        | Llvm.TypeKind.Integer -> build_zext vl tto "casttmp" lbuilder
        | Llvm.TypeKind.Double -> build_fptosi vl tto "casttmp" lbuilder
        | _ -> build_ptrtoint vl tto "casttmp" lbuilder  
        end
      else if (tto = char_type) then 
        begin match classify_type tfrom with 
        | Llvm.TypeKind.Integer -> if (tfrom = int_type) then
              build_trunc vl tto "casttmp" lbuilder 
            else
              build_zext vl tto "casttmp" lbuilder 
        | Llvm.TypeKind.Double -> build_fptoui vl tto "casttmp" lbuilder
       end
      else begin match classify_type tfrom with
        | Llvm.TypeKind.Integer -> 
          build_icmp Icmp.Ne vl (const_int tfrom 0) "casttmp" lbuilder
        | Llvm.TypeKind.Double -> 
          build_fcmp Fcmp.One vl (const_double' 0.0) "casttmp" lbuilder
      end
  | Llvm.TypeKind.Double -> 
      if (tfrom = int_type) then 
        build_sitofp vl double_type "casttmp" lbuilder
      else 
        build_uitofp vl double_type "casttmp" lbuilder
  | _ -> build_bitcast vl tto "casttmp" lbuilder
  end

type const = | C_int of int | C_double of float
let compute_const_binop v1 v2 pos = function
  | O_times -> begin match v1, v2 with
      | C_int i1, C_int i2 -> C_int (i1 * i2)
      | C_double d1, C_double d2 -> C_double (d1 *. d2)
      | _ -> failwith "Unreachable state. \
            (Bad multiplication in array initizalization)"
    end
  | O_div -> begin match v1, v2 with
      | C_int i1, C_int i2 -> C_int (i1 / i2)
      | C_double d1, C_double d2 -> C_double (d1 /. d2)
      | _ -> failwith "Unreachable state. \
            (Bad division in array initizalization)"
    end 
  | O_mod -> begin match v1, v2 with 
      | C_int i1, C_int i2 -> C_int (i1 mod i2)
      | _ -> failwith "Unreachable state. \
            (Bad multiplication in array initizalization)"
    end 
  | O_plus -> begin match v1, v2 with
      | C_int i1, C_int i2 -> C_int (i1 + i2)
      | C_double d1, C_double d2 -> C_double (d1 +. d2)
      | _ -> failwith "Unreachable state. \
            (Bad addition in array initialization)"
    end
  | O_minus ->  begin match v1, v2 with
      | C_int i1, C_int i2 -> C_int (i1 - i2)
      | C_double d1, C_double d2 -> C_double (d1 -. d2)
      | _ -> failwith "Unreachable state. \
            (Bad subtraction in array initialization)"
    end
  | _ -> cg_fail pos "Bad operation in array initializer" 

let const_cast tto v pos = 
  match v with
  | C_int i -> begin match tto with 
      | PTR(INT, 0) -> v
      | PTR(DOUBLE, 0) -> C_double (float_of_int i)
      | _ -> cg_fail pos "Bad casting in array initializer" 
    end
  | C_double d -> begin match tto with 
      | PTR(INT, 0) -> C_int (int_of_float d)
      | PTR(DOUBLE, 0) -> v
      | _ -> cg_fail pos "Bad casting in array initializer" 
    end
let rec compute_const exp =
  match exp.expr with 
  | E_int i -> C_int i
  | E_double d -> C_double d
  | E_uop (O_psgn, e) -> compute_const e
  | E_uop (O_nsgn, e) -> let v = compute_const e in 
    begin match v with 
      | C_int i -> C_int (- i)
      | C_double d -> C_double (-. d)
    end
  | E_binop (e1, op, e2) -> let v1 = compute_const e1 in 
    let v2 = compute_const e2 in 
    compute_const_binop v1 v2 exp.meta op
  | E_tcast (vt, e) -> let v = compute_const e in
    const_cast vt v e.meta
  | E_brack e -> compute_const e
  | _ -> cg_fail exp.meta "Bad array initializer"

let rec to_rval e vl = 
  match Types.is_lval e with 
  | true -> build_load vl "loadtmp" lbuilder 
  | _ -> vl
and prepare_value e = 
  (* If a pointer points to an array, then cast it to point in the "first" element. *)
  (* In any other case, do the classic rval computation. *)
  let vl = codegen_expr e in 
  let t = classify_element_type vl in
  match t with 
  | Llvm.TypeKind.Array -> 
    let t1 =  element_type @@ element_type @@ type_of vl in 
    build_bitcast vl (pointer_type t1) "arrptr" lbuilder
  | _ -> to_rval e vl
and codegen_uop e op = 
  match op with
  | O_ref -> codegen_expr e
  | O_dref -> prepare_value e
  | O_psgn -> prepare_value e
  | O_nsgn -> let rvl = prepare_value e in
      let invert_sign = match classify_type' rvl with 
      | Llvm.TypeKind.Integer -> build_neg  
      | _ -> build_fneg 
    in invert_sign rvl "invtmp" lbuilder
  | O_neg -> let rvl = prepare_value e in
    build_not rvl "nottmp" lbuilder 
and codegen_sc_binop e1 e2 op = 
  let vl1 = prepare_value e1 in 
  let scconst = const_bool' @@ match op with 
  | O_and -> 0 | O_or -> 1 
  in let cond = build_icmp Icmp.Eq vl1 scconst
    "sccond" lbuilder in
  let currbb = insertion_block lbuilder in
  let f = block_parent @@ currbb in
  let fullbb = append_block lcontext "fullbool" f in
  let afterbb = append_block lcontext "endbool" f in
  ignore @@ build_cond_br cond afterbb fullbb lbuilder;
  position_at_end fullbb lbuilder;
  let vl2 = prepare_value e2 in
  ignore @@ build_br afterbb lbuilder;
  position_at_end afterbb lbuilder;
  build_phi [(scconst, currbb); (vl2, fullbb)] "scbtmp" lbuilder
and codegen_binop e1 e2 op = 
  let vl1 = prepare_value e1 in 
  let vl2 = prepare_value e2 in
  let ct1 = classify_type' vl1 in 
  let ct2 = classify_type' vl2 in 
  let cond = ct1 = ct2 && ct1 = Llvm.TypeKind.Pointer in 
  let vl1 =  if (cond && is_null vl1) then 
    const_null @@ type_of vl2 else vl1 in
  let vl2 = if (cond && is_null vl2) then 
    const_null @@ type_of vl1 else vl2 in 
  match op with
  | O_times -> let multiply = match ct1 with
      | Llvm.TypeKind.Integer -> build_mul
      | _ -> build_fmul 
    in multiply vl1 vl2 "multmp" lbuilder 
  | O_div -> let divide = match ct1 with
      | Llvm.TypeKind.Integer -> build_sdiv
      | _ -> build_fdiv
    in divide vl1 vl2 "divtmp" lbuilder
  | O_mod -> build_srem vl1 vl2 "modtmp" lbuilder
  | O_plus -> let add = match ct1 with 
      | Llvm.TypeKind.Integer -> build_add vl1 vl2
      | Llvm.TypeKind.Double -> build_fadd vl1 vl2
      | _ -> build_gep vl1 [|vl2|]
    in add "addtmp" lbuilder      
  | O_minus -> let subtract = match ct1 with 
      | Llvm.TypeKind.Integer -> build_sub vl1 vl2 
      | Llvm.TypeKind.Double -> build_fsub vl1 vl2
      | _ -> let negvl2 = build_neg vl2 "negtmp" lbuilder in 
        build_gep vl1 [|negvl2|]
    in subtract "subtmp" lbuilder
  | O_lt -> let lessthan = match ct1 with 
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.Olt
      | _ -> build_icmp Icmp.Slt
    in lessthan vl1 vl2 "lttmp" lbuilder
  | O_gt -> let greaterthan = match ct1 with 
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.Ogt
      | _ -> build_icmp Icmp.Sgt
    in greaterthan vl1 vl2 "gttmp" lbuilder
  | O_le -> let lessequal = match ct1 with 
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.Ole
      | _ -> build_icmp Icmp.Sle
    in lessequal vl1 vl2 "letmp" lbuilder
  | O_ge -> let greaterequal = match ct1 with 
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.Oge vl1 vl2
      | _ -> build_icmp Icmp.Sge vl1 vl2
    in greaterequal "getmp" lbuilder
  | O_eq -> let equal = match ct1 with 
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.Oeq
      | _ -> build_icmp Icmp.Eq
    in equal vl1 vl2 "eqtmp" lbuilder
  | O_neq -> let inequal = match ct1 with
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.One 
      | _ -> build_icmp Icmp.Ne
    in inequal vl1 vl2 "neqtmp" lbuilder
  | O_comma -> vl2
  | _ -> cg_fail e1.meta "Invalid binary operator"
and codegen_uasgn ~pre e op =  
  let lhs = codegen_expr e in
  let const = match classify_element_type lhs with 
    | Llvm.TypeKind.Double -> {expr = E_double 1.0;
      meta = Lexing.dummy_pos}
    | _ -> {expr = E_int 1;
      meta = Lexing.dummy_pos}
  in let op' = match op with 
    | O_plpl -> O_plus
    | O_mimi -> O_minus
  in let rhs = codegen_binop e const op' in
  ignore @@ build_store rhs lhs lbuilder;
  if (pre) then rhs else
    build_load lhs "loadtmp" lbuilder 
and codegen_basgn e1 e2 op = 
  let lhs = codegen_expr e1 in 
  let rhs = if (op = O_asgn) then begin
    let tmp = prepare_value e2 in 
    let ct = classify_type' tmp in
    if (ct = Llvm.TypeKind.Pointer && is_null tmp) then 
      const_pointer_null' lhs
    else tmp 
  end
  else match op with 
      | O_asgn -> failwith "Taken care of"
      | O_mulasgn -> codegen_binop e1 e2 O_times
      | O_divasgn -> codegen_binop e1 e2 O_div
      | O_modasgn -> codegen_binop e1 e2 O_mod
      | O_plasgn -> codegen_binop e1 e2 O_plus
      | O_minasgn -> codegen_binop e1 e2 O_minus
  in ignore @@ build_store rhs lhs lbuilder; 
  rhs
and codegen_expr exp = 
  match exp.expr with 
  | E_var v -> begin try
      let ent = lookupEntry (id_of_var v) LOOKUP_ALL_SCOPES false in 
      begin match ent.entry_info with 
      | ENTRY_variable inf -> inf.llval
      | _ -> failwith "Found a non-variable entry with the id of a variable"
      end
    with | _ -> let msg = Printf.sprintf "Non-existing variable `%s`" v in 
      cg_fail exp.meta msg
    end
  | E_int d -> const_int' d  
  | E_char c -> const_char' (Char.code c)
  | E_double f -> const_double' f
  | E_str s -> build_global_stringptr s "strtmp" lbuilder
  | E_bool b -> const_bool' (if b then 1 else 0)
  | E_NULL -> const_null @@ pointer_type int_type
  | E_uop (op, e) -> codegen_uop e op
  | E_binop (e1, op, e2) -> begin match op with 
      | O_and | O_or -> codegen_sc_binop e1 e2 op
      | _ -> codegen_binop e1 e2 op
    end
  | E_uasgnpre (op, e) -> codegen_uasgn ~pre:true e op 
  | E_uasgnpost (op, e) -> codegen_uasgn ~pre:false e op
  | E_basgn (e1, op, e2) -> codegen_basgn e1 e2 op 
  | E_tcast (vt, e) -> let vl = prepare_value e in
    let tto = lltype_of_vartype vt in 
    build_edsger_cast vl tto
  | E_ternary (e1, e2, e3) -> begin
      let vl1 = prepare_value e1 in 
      let cond = build_icmp Icmp.Eq vl1 (const_bool' 1)
        "trncond" lbuilder in
      let f = block_parent @@ insertion_block lbuilder in
      let trntbb = append_block lcontext "trntrue" f in
      let trnfbb = append_block lcontext "trnfalse" f in
      let afterbb = append_block lcontext "endtrn" f in
      ignore @@ build_cond_br cond trntbb trnfbb lbuilder;
      position_at_end trntbb lbuilder;
      let vl2 = prepare_value e2 in
      ignore @@ build_br afterbb lbuilder;
      position_at_end trnfbb lbuilder;
      let vl3 = prepare_value e3 in
      ignore @@ build_br afterbb lbuilder;
      position_at_end afterbb lbuilder;
      build_phi [(vl2, trntbb); (vl3, trnfbb)] "trntmp" lbuilder
    end
  | E_new (vt, e) -> let vl = prepare_value e in 
    let t = lltype_of_vartype vt in 
    build_array_malloc t vl "newtmp" lbuilder
  | E_delete e -> let vl = prepare_value e in 
    build_free vl lbuilder
  | E_fcall r -> 
    let fid = id_make r.mangl in
    let entr = lookupEntry fid LOOKUP_ALL_SCOPES true in
    let inf = match entr.entry_info with 
    | ENTRY_function inf -> inf
    | _ -> failwith ("Unknown function: " ^ r.mangl)
    in let callee = inf.llfun in 
    let ps = inf.function_paramlist in
    let envpars = inf.function_envlist in
    let expr_of_env = function
    | name, mode ->
      {expr = E_var name; meta = Lexing.dummy_pos}, mode
    in 
    let exprs = List.map expr_of_env envpars |> 
      List.append (List.combine r.exprs ps) in 
    let prepare = function 
    | e, PASS_BY_REFERENCE -> codegen_expr e 
    | e, PASS_BY_VALUE -> prepare_value e 
    in let args = Array.of_list @@ 
      List.map prepare exprs in 
    let ft = element_type @@ type_of callee in
    let name = if (return_type ft = void_type lcontext) 
      then "" else "calltmp" in
    build_call callee args name lbuilder
  | E_arracc (e1, e2) -> 
    let ptr = prepare_value e1 in 
    let ofst = prepare_value e2 in
    build_gep ptr [|ofst|] "aractmp" lbuilder
  | E_brack e -> codegen_expr e
and iter_stmts = function 
  | [] -> ()
  | h :: t when can_add_terminator () ->
    codegen_stmt h; iter_stmts t
  | h :: t -> ()
and codegen_stmt stm = 
  match stm.stmt with 
  | S_NOP -> ()
  | S_expr e -> ignore @@ codegen_expr e;
  | S_block b -> iter_stmts b;
  | S_if (e, s1, o) -> begin  
      let vl = prepare_value e in 
      let cond = build_icmp Icmp.Ne vl (const_bool' 0) 
        "ifcond" lbuilder in
      let f = block_parent @@ insertion_block lbuilder in
      let thenbb = append_block lcontext "then" f in
      let elsebb = append_block lcontext "else" f in
      let afterbb = append_block lcontext "endif" f in
      ignore @@ build_cond_br cond thenbb elsebb lbuilder;
      position_at_end thenbb lbuilder;
      codegen_stmt s1;
      if (can_add_terminator ()) then 
        ignore @@ build_br afterbb lbuilder;
      position_at_end elsebb lbuilder;
      begin match o with
      | Some s2 -> codegen_stmt s2
      | None -> ()
      end;
      if (can_add_terminator ()) then
        ignore @@ build_br afterbb lbuilder;
      position_at_end afterbb lbuilder; 
    end
  | S_for (o1, o2, o3, s, lo) -> begin 
      match o2 with 
      | Some e2 -> begin
          begin match o1 with 
          | Some e1 -> ignore @@ codegen_expr e1
          | None -> ()
          end;
          let prevbb = insertion_block lbuilder in 
          let f = block_parent @@ prevbb in 
          let loopbb = append_block lcontext "loop" f in
          let bodybb = append_block lcontext "body" f in
          let stepbb = append_block lcontext "step" f in
          let afterbb = append_block lcontext "endfor" f in
          ignore @@ build_br loopbb lbuilder;
          position_at_end loopbb lbuilder;
          begin match lo with 
          | Some l -> ignore @@ 
            newLabel (id_of_label l) stepbb afterbb
          | None -> ()
          end;
          pushLoop stepbb afterbb;
          let vl = prepare_value e2 in 
          let cond = build_icmp Icmp.Eq vl (const_bool' 1) 
            "forcond" lbuilder in
          ignore @@ build_cond_br cond bodybb afterbb lbuilder; 
          position_at_end bodybb lbuilder;
          codegen_stmt s;
          if (can_add_terminator ()) then
            ignore @@ build_br stepbb lbuilder; 
          position_at_end stepbb lbuilder;
          begin match o3 with 
          | Some e3 -> ignore @@ codegen_expr e3
          | None -> ()
          end;
          ignore @@ build_br loopbb lbuilder;                     
          position_at_end afterbb lbuilder; 
          popLoop ()
        end
      | _ -> failwith "Unreachable state (No for-loop condition)" 
    end
  | S_cont o -> let jl = match o with
    | Some l -> let id = id_of_label l in
      let ent = lookupEntry id LOOKUP_CURRENT_SCOPE false in 
      begin match ent.entry_info with 
        | ENTRY_label inf -> inf 
        | _ -> failwith "Found a non label with the id of a label"
      end
    | None -> peekLoop ()
    in ignore @@ build_br jl.stepbb lbuilder
  | S_break o -> let jl = match o with
    | Some l -> let id = id_of_label l in
      let ent = lookupEntry id LOOKUP_CURRENT_SCOPE false in 
      begin match ent.entry_info with 
        | ENTRY_label inf -> inf 
        | _ -> failwith "Found a non label with the id of a label"
      end
    | None -> peekLoop ()
    in ignore @@ build_br jl.afterbb lbuilder
  | S_ret o -> begin match o with
      | Some e -> let retvl = prepare_value e in 
        ignore @@ build_ret retvl lbuilder
      | None -> ignore @@ build_ret_void lbuilder
    end
and codegen_body b = 
  let F_body (decs, stms) = b in 
  List.iter codegen_decl decs;
  iter_stmts stms
and declare_global' vllt pos = function 
  | (vn, None) -> let init = const_null vllt in
    define_global vn init lmodule |> 
    newVariable (id_of_var vn) |> ignore
  | (vn, Some e) -> let v = compute_const e in
    match v with 
    | C_int i -> if (i > 0) then 
        let invl = match classify_type vllt with 
          | Llvm.TypeKind.Double -> const_double' 0.0
          | _ -> const_int' 0 in
        let init = const_array vllt @@ Array.make i invl in
        define_global vn init lmodule |>
        newVariable (id_of_var vn) |> ignore
      else failwith "Non-positive array initializer" 
    | _ -> cg_fail pos "Unreachable State. \
        (Non-int initializer in array declarator)"
and declare_local' vllt pos = function 
  | (vn, None) -> 
    build_alloca vllt vn lbuilder |>
    newVariable (id_of_var vn) |> ignore
  | (vn, Some e) -> let v = compute_const e in 
    match v with 
    | C_int i -> if (i > 0) then 
        let arrt = array_type vllt i in 
        build_alloca arrt vn lbuilder |>
        newVariable (id_of_var vn) |> ignore
      else cg_fail pos "Non-positive array initializer" 
    | _ -> failwith "Unreachable State. \
        (Non-int initializer in array declarator)"
and codegen_vars vt vs pos =
  let vllt = lltype_of_vartype vt in 
  let declare = vllt |> 
    if (inOuterScope ()) then declare_global'
    else declare_local' 
  in List.iter (declare pos) vs
and codegen_header ~def rt fn ps env_opt = 
  let add_parameters_cg ~env f par =
    let pass_mode, name = match par with
    | BYREF (_, vn) -> PASS_BY_REFERENCE, vn
    | BYVAL (_, vn) -> PASS_BY_VALUE, vn
    in 
    if env then
      newEnvParameter name pass_mode f
    else newParameter pass_mode f
  in
  let env_opt = Option.bind env_opt 
    (CGUtils.filter_env ps) in
  (*llps are the ast-parameters that should be included 
    in the llvm representation of the function*)
  let llps = match env_opt with 
    | None -> ps 
    | Some env -> ps @ env
  in 
  let fllt = function_type_of_header rt llps in
  (* Careful! We need the "old" ps when creating the id. *) 
  let pstr = SemUtilities.name_mangling ps in 
  let fid = id_of_func fn pstr in
  let num = (getCounter fid) + 1 in 
  let fn' = CGUtils.funStr_mangled fn pstr num in
  begin match lookup_function fn' lmodule with 
  | Some f -> delete_function f
  | None -> ()  
  end; 
  (* We know the env ONLY for definitions. 
    If two functions have the same llvm name, they are the same.
    But one might have the env parameters (the definition), 
    the declaration might not, so we have to get rid of the extra declaration. *)
  let f = declare_function fn' fllt lmodule in 
  let entr, found = newFunction fid f in 
  if (def) then begin match entr.entry_info with 
    | ENTRY_function inf ->  
      name_parameters (Array.of_list llps) inf.llfun;
      begin match env_opt with
      | None -> ()
      | Some env ->
        List.iter (add_parameters_cg ~env:true entr) env;
      end;
    | _ -> failwith "Unreachable state"
  end;
  if (not found) then begin
    List.iter (add_parameters_cg ~env:false entr) ps;
    endFunctionHeader entr
  end;
  entr
and codegen_fdecl rt fn ps = 
  (* We only care to declare global scope functions, since some of 
    these will be the ones that we will have to link with later on. *)
  if (inOuterScope ()) then
    ignore @@ codegen_header ~def:false
      rt fn ps None
and name_parameters ps f =  
  let fname = value_name f in 
  Array.iteri (fun i a -> 
    let p = ps.(i) in
    let n = CGUtils.get_ast_param_name p in
    set_value_name n a;
  ) (params f)
and parameter_allocation ps envs f = 
    let envs = List.map snd envs in
    let ps = Array.of_list (ps @ envs) in  
    let params = params f in 
    Array.iteri (fun i pi -> 
      let vi = params.(i) in 
      let n = value_name vi in (* We can use value name since 
        we are using the parameters of a brand new function thus
        no counter is needed yet. *)
      let vl = match pi with 
       | PASS_BY_VALUE -> 
          let t = type_of vi in  
          let alc = build_alloca t n lbuilder in 
          ignore @@ build_store vi alc lbuilder;
          alc      
       | _ -> vi in 
      ignore @@ newVariable (id_of_var n) vl;
    ) (ps)
and codegen_fdef rt fn ps b env = 
  let func_entr = codegen_header ~def:true 
    rt fn ps (Some env) in 
  let ENTRY_function inf = func_entr.entry_info in
  let f = inf.llfun in 
  let entrybb = append_block lcontext "entry" f in
  position_at_end entrybb lbuilder;
  openScope ();
  let ps' = inf.function_paramlist in
  let envs' = inf.function_envlist in 
  parameter_allocation ps' envs' f; 
  codegen_body b;  
  closeScope ();
  if (can_add_terminator ()) then            
    match rt with 
    | VOID -> ignore @@ build_ret_void lbuilder;
    | _ -> let ft = element_type @@ type_of f in
      let llrt = return_type ft  in 
      let zero = const_null llrt in
      ignore @@ build_ret zero lbuilder;
and codegen_decl dec = 
  let naive_cg dec = 
    match dec.decl with 
  | D_var (vt, vs) -> codegen_vars vt vs dec.meta
  | D_fun (rt, fn, ps) -> codegen_fdecl rt fn ps
  | D_fdef {rt; fn; p; b; env} -> codegen_fdef rt fn p b env
  in 
  if (inOuterScope ()) then naive_cg dec 
  else begin
    let parent = insertion_block lbuilder in
    naive_cg dec; 
    ignore @@ position_at_end parent lbuilder
  end

let codegen t = 
  initSymbolTable 256;
  List.iter codegen_decl t;
  match Llvm_analysis.verify_module lmodule with 
  | None -> lmodule 
  | Some s -> failwith s