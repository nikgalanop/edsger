open Ast
open Llvm

exception CGFailure of string

let lcontext = global_context failwith "TODO"
let lmodule = create_module lcontext "top-level"
let lbuilder = builder lcontext
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
let double_type = double_type lcontext
and int_type = i16_type lcontext
and char_type = i8_type lcontext
and str_type = const_stringz lcontext
and bool_type = i8_type lcontext (* According to the specification, sizeof(bool) = 1 byte.*)
(* Maybe for better data allignment. *)

let codegen_uop vl = function 
  | O_ref -> failwith "TODO"
  | O_dref -> failwith "TODO"
  | O_psgn -> vl
  | O_nsgn -> faiwith "TODO" (* Have to know the "type" of vl in order to 
                                use the correct build_neg, build_fneg variation*)
                             (* Check typeof etc. *)
  | O_neg -> build_not vl "nottmp" lbuilder 
let codegen_binop vl1 vl2 = function 
  | O_times -> failwith "TODO" (* Must check the types of the two values. *)
  | O_div -> failwith "TODO"
  | O_mod -> failwith "TODO"
  | O_plus -> failwith "TODO" (* Must check the types of the two values. *)
  | O_minus -> failwith "TODO"
  | O_lt -> failwith "TODO" (* << << << *)
  | O_gt -> failwith "TODO"
  | O_le -> failwith "TODO"
  | O_ge -> failwith "TODO"
  | O_eq -> const_int bool_type (vl1 == vl2) (* Reconsider. *)
  | O_neq -> const_int bool_type (vl1 <> vl2) (* Reconsider. *)
  | O_and -> build_and vl1 vl2 "andtmp" lbuilder
  | O_or -> build_or vl1 vl2 "ortmp" lbuilder
  | O_comma -> vl2
let codegen_uasgn = function (* Order matters. This function is not enough I think. *)
  | O_plpl -> failwith "TODO"
  | O_mimi ->  failwith "TODO"
let codegen_basgn = function 
  | O_asgn -> failwith "TODO"
  | O_mulasgn -> failwith "TODO"
  | O_divasgn -> failwith "TODO"
  | O_modasgn -> failwith "TODO"
  | O_plasgn ->  failwith "TODO"
  | O_minasgn ->  failwith "TODO"

let rec codegen_expr exp = 
  match exp.expr with 
  | E_var v -> failwith "TODO"
  | E_int d -> const_int integer_type d  
  | E_char c -> const_int char_type (Char.code c)
  | E_double f -> const_float double_type f
  | E_str s -> failwith "TODO"
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
  | E_new of (vt, e) -> failwith "TODO"
  | E_delete e -> failwith "TODO"
  | E_fcall (fn, es) -> failwith "TODO"  
  | E_arracc (e1, e2) -> failwith "TODO"
  | E_brack e -> codegen_expr e
and codegen_stmt stm = 
  match stm.stmt with 
  | S_NOP -> failwith "TODO"
  | S_expr e -> failwith "TODO"
  | S_block l -> failwith "TODO"
  | S_if (e, s, None) -> failwith "TODO"
  | S_if (e, s1, Some s2) -> failwith "TODO" 
  | S_for of (o1, o2, o3, s, l) -> failwith "TODO"
  | S_cont o -> failwith "TODO"
  | S_break o -> failwith "TODO"
  | S_ret o -> failwith "TODO"
and codegen_body b = 
  let F_body (decs, stms) = b in 
  faiwith "TODO"
and codegen_decl dec = 
  match dec.decl with 
  | D_var (vt, vs) -> failwith "TODO"
  | D_fun (rt, fn, ps) -> failwith "TODO"
  | D_fdef (rt, fn, ps, b) -> failwith "TODO"

let codegen ~opt t = 
  failwith "TODO"