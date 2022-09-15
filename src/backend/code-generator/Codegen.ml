open Ast
open Identifier
open CGSymbol
open Llvm

exception CGFailure of string
let cg_fail msg = 
  raise (CGFailure msg)

let lcontext = global_context ()
let lmodule = create_module lcontext "edsger-program"
let lbuilder = builder lcontext
let int_type = i16_type lcontext
and char_type = i8_type lcontext
and bool_type = i1_type lcontext 
and double_type = double_type lcontext
let const_int = const_int int_type 
and const_char = const_int char_type
and const_bool = const_int bool_type
and const_double = const_float double_type

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
  if (tfrom = tto) then vl 
  else begin match tto with 
    | int_type -> begin match tfrom with 
        | char_type -> build_zext vl tto "casttmp" lbuilder
        | bool_type -> build_zext vl tto "casttmp" lbuilder
        | double_type -> build_fptosi vl tto "casttmp" lbuilder
        | _ -> build_pointercast vl tto "casttmp" lbuilder  
      end
    | char_type -> begin match tfrom with 
        | int_type -> build_trunc vl tto "casttmp" lbuilder 
        | bool_type -> vl (* Revisit. I think that we do not 
          need to do a cast here. (Same sized types) *)
        | double_type -> build_fptoui vl tto "casttmp" lbuilder
        | _ -> build_pointercast vl tto "casttmp" lbuilder  
      end
    | bool_type -> begin match tfrom with 
        | int_type -> build_icmp Icmp.Ne vl (const_int 0) "casttmp" lbuilder
        | char_type -> build_icmp Icmp.Ne vl (const_char 0) "casttmp" lbuilder
        | double_type -> build_fcmp Fcmp.One vl (const_double 0.0) "casttmp" lbuilder
        | _ -> build_pointercast vl tto "casttmp" lbuilder  
      end
    | double_type -> begin match tfrom with
        | int_type -> build_sitofp vl double_type "casttmp" lbuilder
        | char_type -> build_uitofp vl double_type "casttmp" lbuilder
        | bool_type -> build_uitofp vl double_type "casttmp" lbuilder
        | _ -> build_pointercast vl tto "casttmp" lbuilder  
      end
    | _ -> vl (* Revisit: Pointer conversion 
      We do not actually need to cast the pointer value 
      unless not all pointers have the same size in asm, 
      something that we definitely do not want according
      to the edsger language specification.  *)
  end

type const = | C_int of int | C_double of float
let compute_const_binop v1 v2 = function
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
  | _ -> cg_fail "Bad operation in array initializer"

let const_cast tto v = 
  match v with
  | C_int i -> begin match tto with 
      | PTR(INT, 0) -> v
      | PTR(DOUBLE, 0) -> C_double (float_of_int i)
      | _ -> cg_fail "Bad casting in array initializer" 
    end
  | C_double d -> begin match tto with 
      | PTR(INT, 0) -> C_int (int_of_float d)
      | PTR(DOUBLE, 0) -> v
      | _ -> cg_fail "Bad casting in array initializer" 
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
    compute_const_binop v1 v2 op
  | E_tcast (vt, e) -> let v = compute_const e in
    const_cast vt v
  | E_brack e -> compute_const e
  | _ -> cg_fail "Bad array initializer."

let rec to_rval e vl = 
  match Types.is_lval e with 
  | true -> build_load vl "loadtmp" lbuilder 
  | _ -> vl
and compute_rval e =
  let vl = codegen_expr e in
  to_rval e vl
and codegen_uop e op = 
  let vl = codegen_expr e in 
  match op with
  | O_ref -> vl
  | O_dref -> build_load vl "dreftmp" lbuilder (* Revisit this & the array access. *)
    (* Revisit. Do we need to check for a null pointer,
      or we automatically cannot load from a null ptr? *)
  | O_psgn -> to_rval e vl
  | O_nsgn -> let rvl = to_rval e vl in
      let invert_sign = match type_of rvl with 
      | int_type -> build_neg 
      | _ -> build_fneg 
    in invert_sign rvl "invtmp" lbuilder
  | O_neg -> let rvl = to_rval e vl in
    build_not rvl "nottmp" lbuilder 
and codegen_sc_binop e1 e2 op = 
  let vl1 = compute_rval e1 in 
  let scconst = const_bool @@ match op with 
  | O_and -> 0 | O_or -> 1 
  in let cond = build_icmp Icmp.Eq vl1 scconst
    "sccond" lbuilder in
  let currbb = insertion_block lbuilder in
  let f = block_parent @@ currbb in
  let fullbb = append_block lcontext "fullbool" f in
  let afterbb = append_block lcontext "endbool" f in
  ignore @@ build_cond_br cond afterbb fullbb lbuilder;
  position_at_end fullbb lbuilder;
  let vl2 = compute_rval e2 in
  ignore @@ build_br afterbb lbuilder;
  position_at_end afterbb lbuilder;
  build_phi [(scconst, currbb); (vl2, fullbb)] "scbtmp" lbuilder
and codegen_binop e1 e2 = 
  let vl1 = compute_rval e1 in 
  let vl2 = compute_rval e2 in 
  codegen_binop' vl1 vl2
and codegen_binop' vl1 vl2 = function  
  | O_times -> let multiply = match type_of vl1 with
      | int_type -> build_mul
      | _ -> build_fmul 
    in multiply vl1 vl2 "multmp" lbuilder 
  | O_div -> let divide = match type_of vl1 with
      | int_type -> build_sdiv
      | _ -> build_fdiv
    in divide vl1 vl2 "divtmp" lbuilder
  | O_mod -> build_srem vl1 vl2 "modtmp" lbuilder
  | O_plus -> let add = match type_of vl1 with 
      | int_type -> build_add vl1 vl2 
      | double_type -> build_fadd vl1 vl2 
      | _ -> build_gep vl1 [|const_int 0; vl2|]
    in add "addtmp" lbuilder      
  | O_minus -> let subtract = match type_of vl1 with 
      | int_type -> build_sub vl1 vl2 
      | double_type -> build_fsub vl1 vl2
      | _ -> let negvl2 = build_neg vl2 "negtmp" lbuilder in 
        build_gep vl1 [|const_int 0; negvl2|]
    in subtract "subtmp" lbuilder
  | O_lt -> let lessthan = match type_of vl1 with 
      | double_type -> build_fcmp Fcmp.Olt
      | _ -> build_icmp Icmp.Slt
    in lessthan vl1 vl2 "lttmp" lbuilder
  | O_gt -> let greaterthan = match type_of vl1 with 
      | double_type -> build_fcmp Fcmp.Ogt
      | _ -> build_icmp Icmp.Sgt
    in greaterthan vl1 vl2 "gttmp" lbuilder
  | O_le -> let lessequal = match type_of vl1 with 
      | double_type -> build_fcmp Fcmp.Ole
      | _ -> build_icmp Icmp.Sle
    in lessequal vl1 vl2 "letmp" lbuilder
  | O_ge -> let greaterequal = match type_of vl1 with 
      | double_type -> build_fcmp Fcmp.Oge vl1 vl2
      | _ -> build_icmp Icmp.Sge vl1 vl2
    in greaterequal "getmp" lbuilder
  | O_eq -> let equal = match classify_type @@ type_of vl1 with 
      | Llvm.TypeKind.Double -> build_fcmp Fcmp.Oeq
      | _ -> build_icmp Icmp.Eq
    in equal vl1 vl2 "eqtmp" lbuilder
  | O_neq -> let inequal = match type_of vl1 with
      | double_type -> build_fcmp Fcmp.One 
      | _ -> build_icmp Icmp.Ne
    in inequal vl1 vl2 "neqtmp" lbuilder
  | O_comma -> vl2
  | _ -> cg_fail "Invalid binary operator."
and codegen_uasgn ~pre e op =  
  let lhs = codegen_expr e in
  let vl = to_rval e lhs in 
  let const = match type_of vl with 
    | double_type -> const_double 1.
    | _ -> const_int 1 
  in let op' = match op with 
    | O_plpl -> O_plus
    | O_mimi -> O_minus
  in let rhs = codegen_binop' vl const op' in
  ignore @@ build_store rhs lhs lbuilder;
  if (pre) then rhs else vl
and codegen_basgn e1 e2 op = 
  let lhs = codegen_expr e1 in 
  let vl2 = compute_rval e2 in
  let rhs = if (op = O_asgn) then vl2 
    else let vl1 = to_rval e1 lhs 
    in match op with 
      | O_asgn -> failwith "Taken care of."
      | O_mulasgn -> codegen_binop' vl1 vl2 O_times
      | O_divasgn -> codegen_binop' vl1 vl2 O_div
      | O_modasgn -> codegen_binop' vl1 vl2 O_mod
      | O_plasgn -> codegen_binop' vl1 vl2 O_plus
      | O_minasgn -> codegen_binop' vl1 vl2 O_minus
  in ignore @@ build_store rhs lhs lbuilder; 
  rhs
and codegen_expr exp = 
  match exp.expr with 
  | E_var v -> let ent = lookupEntry (id_of_var v) LOOKUP_ALL_SCOPES true in 
    begin match ent.entry_info with 
      | ENTRY_variable inf -> inf.llval
      | _ -> failwith "Zoinks Scoob."
    end
  | E_int d -> const_int d  
  | E_char c -> const_char (Char.code c)
  | E_double f -> const_double f
  | E_str s -> build_global_stringptr s "strtmp" lbuilder
  | E_bool b -> const_bool (if b then 1 else 0)
  | E_NULL -> const_pointer_null (pointer_type int_type)
  | E_uop (op, e) -> codegen_uop e op
  | E_binop (e1, op, e2) -> begin match op with 
      | O_and | O_or -> codegen_sc_binop e1 e2 op
      | _ -> codegen_binop e1 e2 op
    end
  | E_uasgnpre (op, e) -> codegen_uasgn ~pre:true e op 
  | E_uasgnpost (op, e) -> codegen_uasgn ~pre:false e op
  | E_basgn (e1, op, e2) -> codegen_basgn e1 e2 op 
  | E_tcast (vt, e) -> let vl = compute_rval e in
    let tto = lltype_of_vartype vt in 
    build_edsger_cast vl tto
  | E_ternary (e1, e2, e3) -> begin
      let vl1 = compute_rval e1 in 
      let cond = build_icmp Icmp.Eq vl1 (const_bool 1)
        "trncond" lbuilder in
      let f = block_parent @@ insertion_block lbuilder in
      let trntbb = append_block lcontext "trntrue" f in
      let trnfbb = append_block lcontext "trnfalse" f in
      let afterbb = append_block lcontext "endtrn" f in
      ignore @@ build_cond_br cond trntbb trnfbb lbuilder;
      position_at_end trntbb lbuilder;
      let vl2 = compute_rval e2 in
      ignore @@ build_br afterbb lbuilder;
      position_at_end trnfbb lbuilder;
      let vl3 = compute_rval e3 in
      ignore @@ build_br afterbb lbuilder;
      position_at_end afterbb lbuilder;
      build_phi [(vl2, trntbb); (vl3, trnfbb)] "trntmp" lbuilder
    end
  | E_new (vt, e) -> let vl = compute_rval e in (* REVISIT: *) 
    let t = lltype_of_vartype vt in 
    (* Revisit. Should check that vl is positive. 
      Is the following code enough/correct? *)
    build_array_malloc t vl "newtmp" lbuilder
  | E_delete e -> let vl = compute_rval e in 
    build_free vl lbuilder
  | E_fcall (fn, es) -> failwith "TODO 2"
    (* let f = find function ...... in
      let name = if (is_void f) then "" else "calltmp" in
      let args = args_of_parameter_list es in
      build_call f args name lbuilder *)  
  | E_arracc (e1, e2) -> let arr = codegen_expr e1 in 
    let ofst = compute_rval e2 in
    build_gep arr [|const_int 0; ofst|] "aractmp" lbuilder (* Needs a load maybe :) *)
  | E_brack e -> codegen_expr e
and codegen_stmt stm = 
  match stm.stmt with 
  | S_NOP -> ()
  | S_expr e -> ignore @@ codegen_expr e;
  | S_block b -> List.iter codegen_stmt b;
  | S_if (e, s1, o) -> begin  
      let vl = compute_rval e in 
      let cond = build_icmp Icmp.Ne vl (const_bool 0) 
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
      match o with
      | Some s2 -> codegen_stmt s2;
      | None -> ();
      if (can_add_terminator ()) then
        ignore @@ build_br afterbb lbuilder;
      position_at_end afterbb lbuilder; 
    end
  | S_for (o1, o2, o3, s, lo) -> begin 
      match o2 with 
      | Some e2 -> begin
          match o1 with 
          | Some e1 -> ignore @@ codegen_expr e1;
          | None -> ();
          let prevbb = insertion_block lbuilder in 
          let f = block_parent @@ prevbb in 
          let loopbb = append_block lcontext "loop" f in
          let bodybb = append_block lcontext "body" f in
          let stepbb = append_block lcontext "step" f in
          let afterbb = append_block lcontext "endfor" f in
          ignore @@ build_br loopbb lbuilder;
          position_at_end loopbb lbuilder;
          match lo with 
          | Some l -> ignore @@ 
            newLabel (id_of_label l) stepbb afterbb;
          | None -> ();
          pushLoop stepbb afterbb;
          let vl = compute_rval e2 in 
          let cond = build_icmp Icmp.Eq vl (const_bool 1) 
            "forcond" lbuilder in
          ignore @@ build_cond_br cond bodybb afterbb lbuilder; 
          position_at_end bodybb lbuilder;
          codegen_stmt s;
          if (can_add_terminator ()) then
            ignore @@ build_br stepbb lbuilder; 
          position_at_end stepbb lbuilder;
          match o3 with 
          | Some e3 -> ignore @@ codegen_expr e2; 
          | None -> ();
          ignore @@ build_br loopbb lbuilder;                     
          position_at_end afterbb lbuilder; 
          popLoop ()
        end
      | _ -> failwith "Unreachable state. (No for-loop condition)" 
    end
  | S_cont o -> let jl = match o with
    | Some l -> let id = id_of_label l in
      let ent = lookupEntry id LOOKUP_CURRENT_SCOPE false in 
      begin match ent.entry_info with 
        | ENTRY_label inf -> inf 
        | _ -> failwith "Found a non label with the id of a label."
      end
    | None -> peekLoop ()
    in ignore @@ build_br jl.stepbb lbuilder
  | S_break o -> let jl = match o with
    | Some l -> let id = id_of_label l in
      let ent = lookupEntry id LOOKUP_CURRENT_SCOPE false in 
      begin match ent.entry_info with 
        | ENTRY_label inf -> inf 
        | _ -> failwith "Found a non label with the id of a label."
      end
    | None -> peekLoop ()
    in ignore @@ build_br jl.afterbb lbuilder
  | S_ret o -> begin match o with
      | Some e -> let retvl = compute_rval e in 
        ignore @@ build_ret retvl lbuilder
      | None -> ignore @@ build_ret_void lbuilder
    end
and codegen_body b = 
  let F_body (decs, stms) = b in 
  List.iter codegen_decl decs;
  List.iter codegen_stmt stms
and declare_global' vllt = function 
  | (vn, None) -> declare_global vllt vn lmodule |> 
    newVariable (id_of_var vn) |> ignore
  | (vn, Some e) -> let v = compute_const e in
    match v with 
    | C_int i -> if (i > 0) then 
        let invl = if (vllt = double_type) then 
          const_double 0.0 else const_int 0 in
        let init = const_array vllt @@ Array.make i invl in
        define_global vn init lmodule |> 
        newVariable (id_of_var vn) |> ignore
      else cg_fail "Non-positive array initializer." 
    | _ -> failwith "Unreachable State. \
          (Non-int initializer in array declarator)"
and declare_local' vllt = function 
  | (vn, None) -> 
    build_alloca vllt vn lbuilder |>
    newVariable (id_of_var vn) |> ignore
  | (vn, Some e) ->let vl = codegen_expr e in 
    build_array_alloca vllt vl vn lbuilder |> 
    newVariable (id_of_var vn) |> ignore
and codegen_vars vt vs =
  let vllt = lltype_of_vartype vt in 
  let declare = vllt |> 
    if (inOuterScope ()) then declare_global'
    else declare_local'
  in List.iter declare vs
and codegen_header rt fn ps = 
  let fllt = function_type_of_header rt ps in 
  ignore @@ declare_function fn fllt lmodule
and codegen_fdecl rt fn ps = 
  (* We only care to declare global scope functions, since some of 
    these will be the ones that we will have to link with later on. *)
  if (inOuterScope ()) then
    codegen_header rt fn ps
and codegen_fdef rt fn ps b = 
    failwith "TODO 6"
and codegen_decl dec = 
  match dec.decl with 
  | D_var (vt, vs) -> codegen_vars vt vs
  | D_fun (rt, fn, ps) -> () (* codegen_fdecl rt fn ps *)
  | D_fdef (rt, fn, ps, b) -> 
    let ft = function_type (void_type lcontext) [||] in
    let f = define_function "main" ft lmodule in 
    let entrybb = entry_block f in
    position_at_end entrybb lbuilder;
    openScope ();
    codegen_body b;
    closeScope ();
    if (can_add_terminator ()) then 
      ignore @@ build_ret_void lbuilder
    (* codegen_fdef rt fn ps b *)
let codegen t = 
  initSymbolTable 256;
  List.iter codegen_decl t;
  match Llvm_analysis.verify_module lmodule with 
  | None -> lmodule 
  | Some s -> cg_fail s