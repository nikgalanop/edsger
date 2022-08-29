open Ast
open Llvm

exception CGFailure of string

let lcontext = global_context ()
let lmodule = create_module lcontext "edsger-program"
let lbuilder = builder lcontext
(* let named_values : (string, llvalue) Hashtbl.t = Hashtbl.create 10 *)
(* Could be a good idea to use the symbol table that we used for semantic analysis. *)
let int_type = i16_type lcontext
and char_type = i8_type lcontext
and bool_type = i8_type lcontext (* According to the specification, sizeof(bool) = 1 byte.*)
and double_type = double_type lcontext
let const_int = const_int int_type
and const_char = const_int char_type
and const_bool = const_int bool_type
and const_double = const_float double_type

let lltype_of_ast t = 
  failwith "TODO"

let rec codegen_uop vl = function 
  | O_ref -> vl (* !! *)
  | O_dref -> failwith "TODO"
  | O_psgn -> vl
  | O_nsgn -> let invert_sign = match type_of vl with 
    | int_type -> build_neg 
    | _ -> build_fneg 
    in invert_sign vl "invtmp" lbuilder
  | O_neg -> build_not vl "nottmp" lbuilder 
and codegen_sc_binop e1 e2 op = 
  let vl1 = codegen_expr e1 in 
  let scconst = const_bool @@ match op with 
  | O_and -> 0 | O_or -> 1 
  in let cond = build_icmp Icmp.Eq vl scconst 
    (* Revisit. If true is just a value <> 0, this needs to be changed. *)
    "sccond" lbuilder in (* Revisit. Maybe needs a load. *)
  let currbb = insertion_block lbuilder in
  let f = block_parent @@ currbb in
  let fullbb = append_block lcontext "fullbool" f in
  let afterbb = append_block lcontext "endbool" f in
  ignore @@ build_cond_br cond afterbb fullbb lbuilder;
  position_at_end fullbb lbuilder;
  let vl2 = codegen_expr e2 in
  ignore @@ build_br afterbb lbuilder;
  position_at_end afterbb lbuilder;
  build_phi [(scconst, currbb); (vl2, fullbb)] "scbtmp" lbuilder
and codegen_binop vl1 vl2 = function 
  | O_times -> let multiply = match type_of vl1 with
      | int_type -> build_mul
      | _ -> build_fmul 
    in multiply vl1 vl2 "multmp" lbuilder 
  | O_div -> let divide = match type_of vl1 with
      | int_type -> build_sdiv
      | _ -> build_fdiv
    in divide vl1 vl2 "divtmp" lbuilder
  | O_mod -> build_srem vl1 vl2 "modtmp" lbuilder
  | O_plus -> begin 
      match type_of vl1 with 
      | int_type -> build_add vl1 vl2 "addtmp" lbuilder
      | double_type -> build_fadd vl1 vl2 "addtmp" lbuilder
      | _ ->  failwith "TODO" (* Pointer type?? *)
    end
  | O_minus -> begin 
      match type_of vl1 with 
      | int_type -> build_sub vl1 vl2 "subtmp" lbuilder
      | double_type -> build_fsub vl1 vl2 "subtmp" lbuilder
      | _ ->  failwith "TODO" (* Pointer type?? *)
    end
  | O_lt -> begin 
      match type_of vl1 with 
      | int_type -> build_icmp Icmp.Slt vl1 vl2 "lttmp" lbuilder
      | bool_type -> build_icmp Icmp.Ult vl1 vl2 "lttmp" lbuilder
      | double_type -> build_fcmp Fcmp.Olt vl1 vl2 "lttmp" lbuilder
      | _ -> failwith "TODO" (* Pointer type?? *)
    end 
  | O_gt -> begin 
      match type_of vl1 with 
      | int_type -> build_icmp Icmp.Sgt vl1 vl2 "gttmp" lbuilder
      | bool_type -> build_icmp Icmp.Ugt vl1 vl2 "gttmp" lbuilder
      | double_type -> build_fcmp Fcmp.Ogt vl1 vl2 "gttmp" lbuilder
      | _ -> failwith "TODO" (* Pointer type?? *)
    end 
  | O_le -> begin 
      match type_of vl1 with 
      | int_type -> build_icmp Icmp.Sle vl1 vl2 "letmp" lbuilder
      | bool_type -> build_icmp Icmp.Ule vl1 vl2 "letmp" lbuilder
      | double_type -> build_fcmp Fcmp.Ole vl1 vl2 "letmp" lbuilder
      | _ -> failwith "TODO" (* Pointer type?? *)
    end 
  | O_ge -> begin 
      match type_of vl1 with 
      | int_type -> build_icmp Icmp.Sge vl1 vl2 "getmp" lbuilder
      | bool_type -> build_icmp Icmp.Uge vl1 vl2 "getmp" lbuilder
      | double_type -> build_fcmp Fcmp.Oge vl1 vl2 "getmp" lbuilder
      | _ -> failwith "TODO" (* Pointer type?? *)
    end 
  | O_eq -> let equal = match type_of vl1 with 
      | double_type -> build_fcmp Fcmp.Oeq
      | _ -> build_icmp Icmp.Eq
    in equal vl1 vl2 "eqtmp" lbuilder
  | O_neq -> let inequal = match type_of vl1 with
      | double_type -> build_fcmp Fcmp.One 
      | _ -> build_icmp Icmp.Ne 
    in inequal vl1 vl2 "neqtmp" lbuilder
  | O_comma -> vl2
  | _ -> failwith "Invalid operator."
and codegen_uasgn vl op =  
  let const = match t with 
  | double_type -> const_double 1.
  | _ -> const_int 1 
  in let asgn = match op with 
  | O_plpl -> O_plasgn 
  | O_mimi -> O_modasgn
  in codegen_basgn vl const asgn 
and codegen_basgn vl1 vl2 op = 
  let lhs = vl1 in 
  let rhs = match op with 
  | O_asgn -> vl2
  | O_mulasgn -> codegen_binop vl1 vl2 O_times
  | O_divasgn -> codegen_binop vl1 vl2 O_div
  | O_modasgn -> codegen_binop vl1 vl2 O_mod
  | O_plasgn -> codegen_binop vl1 vl2 O_plus
  | O_minasgn -> codegen_binop vl1 vl2 O_minus
  in (* Revisit. What is rhs? Do we need a load? *)
  (* Can we simply return the result of build_store?*)
  ignore @@ build_store rhs lhs lbuilder; 
  lhs
and codegen_expr exp = 
  match exp.expr with 
  | E_var v -> failwith "TODO"
  | E_int d -> const_int d  
  | E_char c -> const_char (Char.code c)
  | E_double f -> const_double f
  | E_str s -> build_global_stringptr s "strtmp" lbuilder
  | E_bool b -> const_bool (if b then 1 else 0)
  | E_NULL -> const_pointer_null (pointer_type int_type)
  | E_uop (op, e) -> let vl = codegen_expr e in 
    codegen_uop vl op
  | E_binop (e1, op, e2) -> begin match op with 
      | O_and | O_or -> codegen_sc_binop e1 e2 op
      | _ -> let vl1 = codegen_expr e1 in 
        let vl2 = codegen_expr e2 in codegen_binop vl1 vl2 op
    end
  | E_uasgnpre (op, e) -> let vl = codegen_expr e in 
    codegen_uasgn vl op
  | E_uasgnpost (op, e) -> let vl = codegen_expr e in 
    ignore @@ codegen_uasgn vl op; vl
  | E_basgn (e1, op, e2) -> let vl1 = codegen_expr e1 in
    let vl2 = codegen_expr e2 in codegen_basgn vl1 vl2 op 
  | E_tcast (vt, e) -> begin 
      let vl = codegen_expr e in
      let tfrom = type_of vl in 
      let tto = lltype_of_ast vt in 
      failwith "TODO"
    end 
  | E_ternary (e1, e2, e3) -> begin
      let vl1 = codegen_expr e1 in 
      let cond = build_icmp Icmp.Eq vl (const_bool 1)
        "trncond" lbuilder in (* Revisit. Maybe needs a load. *)
      let f = block_parent @@ insertion_block lbuilder in
      let trntbb = append_block lcontext "trntrue" f in
      let trnfbb = append_block lcontext "trnfalse" f in
      let afterbb = append_block lcontext "endtrn" f in
      ignore @@ build_cond_br cond trntbb trnfbb lbuilder;
      position_at_end trntbb lbuilder;
      let vl2 = codegen_expr e2 in
      ignore @@ build_br afterbb lbuilder;
      position_at_end trnfbb lbuilder;
      let vl3 = codegen_expr e3 in
      ignore @@ build_br afterbb lbuilder;
      position_at_end afterbb lbuilder;
      build_phi [(vl2, trntbb); (vl3, trnfbb)] "trntmp" lbuilder
    end
  | E_new (vt, e) -> let vl = codegen_expr e in 
    let t = lltype_of_ast vt in (* Revisit. Should check that vl is positive. *)
    failwith "TODO"
  | E_delete e -> let vl = codegen_expr e in 
    build_free vl lbuilder
  | E_fcall (fn, es) -> failwith "TODO"  
  | E_arracc (e1, e2) -> failwith "TODO"
  | E_brack e -> codegen_expr e
and codegen_stmt stm = 
  match stm.stmt with 
  | S_NOP -> ()
  | S_expr e -> ignore @@ codegen_expr e
  | S_block l -> List.iter codegen_stmt l
  | S_if (e, s1, o) -> begin 
      let vl = codegen_expr e in 
      let cond = build_icmp Icmp.Ne vl (const_bool 0) 
        "ifcond" lbuilder in (* Revisit. Maybe needs a load. *)
      let f = block_parent @@ insertion_block lbuilder in
      let thenbb = append_block lcontext "then" f in
      let elsebb = append_block lcontext "else" f in
      let afterbb = append_block lcontext "endif" f in
      ignore @@ build_cond_br cond thenbb elsebb lbuilder;
      position_at_end thenbb lbuilder;
      codegen_stmt s1;
      ignore @@ build_br afterbb lbuilder;
      position_at_end elsebb lbuilder;
      match o with
      | Some s2 -> codegen_stmt s2;
      | None -> ();
      ignore @@ build_br afterbb lbuilder;
      position_at_end afterbb lbuilder;
    end
  | S_for (o1, o2, o3, s, l) -> begin 
      match o2 with 
      | Some e2 -> begin
          match o1 with 
          | Some e1 -> ignore @@ codegen_expr e1;
          | None -> ();
          let prevbb = insertion_block lbuilder in 
          let f = block_parent @@ prevbb in 
          let loopbb = append_block lcontext "loop" f in
          let bodybb = append_block lcontext "body" f in
          let afterbb = append_block lcontext "endfor" f in
          ignore @@ build_br loopbb lbuilder;
          position_at_end loopbb lbuilder;
          (* TODO . . . . . . . . . . . . . . . . . . . . . *)
          (* Label Handling??? *)
        end
      | _ -> failwith "Should not reach this state."
    end
  | S_cont o -> failwith "TODO"
  | S_break o -> failwith "TODO"
  | S_ret o -> failwith "TODO"
and codegen_body b = 
  let F_body (decs, stms) = b in 
  List.iter codegen_stmt stms
and codegen_decl dec = 
  match dec.decl with 
  | D_var (vt, vs) -> failwith "TODO"
  | D_fun (rt, fn, ps) -> failwith "TODO"
  | D_fdef (rt, fn, ps, b) -> codegen_body b

let codegen t = 
  failwith "TODO"