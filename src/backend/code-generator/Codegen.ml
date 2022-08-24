open Ast
open Llvm

exception CGFailure of string

let lcontext = global_context ()
let lmodule = create_module lcontext "edsger-module"
let lbuilder = builder lcontext
let named_values : (string, llvalue) Hashtbl.t = Hashtbl.create 10
let int_type = i16_type lcontext
and char_type = i8_type lcontext
and bool_type = i8_type lcontext (* According to the specification, sizeof(bool) = 1 byte.*)
and double_type = double_type lcontext

let codegen_uop vl = function 
  | O_ref -> failwith "TODO"
  | O_dref -> failwith "TODO"
  | O_psgn -> vl
  | O_nsgn -> let t = type_of vl in 
    let invert_sign = if (t = int_type) then build_neg 
      else build_fneg in 
    invert_sign vl "invtmp" lbuilder
  | O_neg -> build_not vl "nottmp" lbuilder 
let codegen_binop vl1 vl2 = function 
  | O_times -> let t = type_of vl1 in
    let multiply = if (t = int_type) then build_mul
      else build_fmul in 
    multiply vl1 vl2 "multmp" lbuilder 
  | O_div -> let t = type_of vl1 in 
    let divide = if (t = int_type) then build_sdiv
      else build_fdiv in 
    divide vl1 vl2 "divtmp" lbuilder
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
  | O_eq -> let t = type_of vl1 in
    let equal = if (t = double_type) then build_fcmp Fcmp.Oeq 
      else build_icmp Icmp.Eq in 
    equal vl1 vl2 "eqtmp" lbuilder
  | O_neq -> let t = type_of vl1 in
    let inequal = if (t = double_type) then build_fcmp Fcmp.One 
      else build_icmp Icmp.Ne in 
    inequal vl1 vl2 "eqtmp" lbuilder
  | O_and -> build_and vl1 vl2 "andtmp" lbuilder
  | O_or -> build_or vl1 vl2 "ortmp" lbuilder
  | O_comma -> vl2
let codegen_uasgn vl = function (* Order matters. This function is not enough I think. 
                                  We need one for pre and one for post.*)
  | O_plpl -> failwith "TODO"
  | O_mimi -> failwith "TODO"
let codegen_basgn = function 
  | O_asgn -> failwith "TODO"
  | O_mulasgn -> failwith "TODO"
  | O_divasgn -> failwith "TODO"
  | O_modasgn -> failwith "TODO"
  | O_plasgn -> failwith "TODO"
  | O_minasgn -> failwith "TODO"
let rec codegen_expr exp = 
  match exp.expr with 
  | E_var v -> failwith "TODO"
  | E_int d -> const_int int_type d  
  | E_char c -> const_int char_type (Char.code c)
  | E_double f -> const_float double_type f
  | E_str s -> const_stringz lcontext s (* Revise? Check how this interacts with the "Edsger library" *)
  | E_bool b -> let vl = if b then 1 else 0 in 
    const_int bool_type vl 
  | E_NULL -> failwith "TODO" (* :) *)
  | E_uop (op, e) -> let vl = codegen_expr e in 
    codegen_uop vl op
  | E_binop (e1, op, e2) -> let vl1 = codegen_expr e1 in 
    let vl2 = codegen_expr e2 in codegen_binop vl1 vl2 op
  | E_uasgnpre (op, e) -> let vl = codegen_expr e in 
    codegen_uasgn vl op
  | E_uasgnpost (op, e) -> failwith "TODO"
  | E_basgn (e1, op, e2) -> failwith "TODO"
  | E_tcast (vt, e) -> failwith "TODO"
  | E_ternary (e1, e2, e3) -> failwith "TODO"
  | E_new (vt, e) -> failwith "TODO"
  | E_delete e -> failwith "TODO"
  | E_fcall (fn, es) -> failwith "TODO"  
  | E_arracc (e1, e2) -> failwith "TODO"
  | E_brack e -> codegen_expr e
and codegen_stmt stm = 
  match stm.stmt with 
  | S_NOP -> failwith "TODO"
  | S_expr e -> ignore @@ codegen_expr e
  | S_block l -> failwith "TODO"
  | S_if (e, s, None) -> failwith "TODO"
  | S_if (e, s1, Some s2) -> failwith "TODO" 
  | S_for (o1, Some e2, o3, s, l) -> failwith "TODO"
  | S_for (_, None, _, _, _) -> 
    failwith "Should not reach this state."
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