type var = string
type fname = string
type label = string
type uop = O_ref | O_dref | O_psgn | O_nsgn | O_neg
type binop = O_times | O_div | O_mod | O_plus | O_minus
             | O_lt | O_gt | O_le | O_ge | O_eq | O_neq 
             | O_and | O_or | O_comma
type uassign = O_plpl | O_mimi
type bassign = O_asgn | O_mulasgn | O_divasgn 
              | O_modasgn | O_plasgn | O_minasgn
type primitive = INT | CHAR | BOOL | DOUBLE 
and vartype =  PTR of primitive * int
and rettype = VOID | RET of vartype
and parameter = BYREF of vartype * var | BYVAL of vartype * var

type ast_decl =
  | D_var of vartype * (var * ast_expr option) list
  | D_fun of  rettype * fname * parameter list  
  | D_fdef of rettype * fname * parameter list * ast_body
  | D_TODO
and ast_body = 
  | F_body of ast_decl list * ast_stmt list 
and ast_stmt =
  | S_NOP
  | S_expr of ast_expr
  | S_block of ast_stmt list
  | S_if of ast_expr * ast_stmt * ast_stmt option 
  | S_for of ast_expr option * ast_expr option * ast_expr option * ast_stmt * label option
  | S_cont of label option 
  | S_break of label option
  | S_ret of ast_expr option
  | S_TODO
and ast_expr = 
  | E_var of var
  | E_int of int 
  | E_char of char 
  | E_double of float 
  | E_str of string
  | E_bool of bool
  | E_NULL
  | E_uop of uop * ast_expr
  | E_binop of ast_expr * binop * ast_expr
  | E_uasgnpre of uassign * ast_expr
  | E_uasgnpost of uassign * ast_expr
  | E_basgn of ast_expr * bassign * ast_expr
  | E_tcast of vartype * ast_expr
  | E_ternary of ast_expr * ast_expr * ast_expr
  | E_new of vartype * ast_expr option 
  | E_delete of ast_expr
  | E_fcall of fname * ast_expr list  
  | E_arracc of ast_expr * ast_expr
  | E_brack of ast_expr (* <- Consider what to do with ( expr ). *)
  | E_TODO

type ast = ast_decl list

let pointer_str i = 
  String.make i '*'
let primtype_str t =
  let PTR(p, i) = t in 
  let s = pointer_str i in
  match p with 
  | INT -> "INT" ^ s
  | CHAR -> "CHAR" ^ s
  | BOOL -> "BOOL" ^ s
  | DOUBLE -> "DOUBLE" ^ s
let vartype_str v = 
  primtype_str v
let rettype_str = function
  | VOID -> "VOID"
  | RET t -> vartype_str t
let label_str = function
  | Some s -> s
  | _ -> ""
let uop_str = function 
  | O_ref -> "&"
  | O_dref -> "*"
  | O_psgn -> "+"
  | O_nsgn -> "-"
  | O_neg -> "!"
let binop_str = function 
  | O_times -> "*"
  | O_div -> "/"
  | O_mod -> "%"
  | O_plus -> "+"
  | O_minus -> "-"
  | O_lt -> "<"
  | O_gt -> ">"
  | O_le -> "<="
  | O_ge -> ">="
  | O_eq -> "=="
  | O_neq -> "!="
  | O_and -> "&&"
  | O_or -> "||"
  | O_comma -> ","
let uassign_str = function 
  | O_plpl -> "++"
  | O_mimi -> "--"
let bassign_str = function 
  | O_asgn -> "="
  | O_mulasgn -> "*="
  | O_divasgn -> "/="
  | O_modasgn -> "%="
  | O_plasgn -> "+="
  | O_minasgn -> "-="


let rec print_expr = 
  let open Printf in
  function
  | E_var s -> eprintf "E_var(%s)" s
  | E_int i -> eprintf "E_int(%d)" i
  | E_char c -> eprintf "E_char(%c)" c
  | E_double d -> eprintf "E_double(%f)" d
  | E_str s -> eprintf "E_str(%s)" s
  | E_bool b when b -> eprintf "E_bool(True)"
  | E_bool b -> eprintf "E_bool(False)"
  | E_NULL -> eprintf "E_NULL()"
  | E_uop (op, e) -> eprintf "E_uop(%s," (uop_str op); print_expr e; eprintf ")"
  | E_binop (e1, op, e2) -> eprintf "E_binop("; print_expr e1; eprintf ", %s, " (binop_str op); print_expr e2; eprintf ")"
  | E_uasgnpre (ua, e) -> eprintf "E_uasgnpre(%s, " (uassign_str ua); print_expr e; eprintf ")"
  | E_uasgnpost (ua, e) -> eprintf "E_uasgnpost(%s, " (uassign_str ua); print_expr e; eprintf ")"
  | E_basgn (e1, op, e2) -> eprintf "E_basgn("; print_expr e1; eprintf ", %s, " (bassign_str op); print_expr e2; eprintf ")"
  | E_tcast (v, e) -> eprintf "E_tcast(%s, " (vartype_str v); print_expr e;
  | E_ternary (e1, e2, e3) -> eprintf "E_ternary("; print_expr e1; eprintf ", ";  print_expr e2; eprintf ", "; print_expr e3; eprintf ")";
  | E_new (v, None) ->  eprintf "E_new(%s)" (vartype_str v)
  | E_new (v, Some e) -> eprintf "E_new(%s" (vartype_str v); eprintf ", "; print_expr e; eprintf ")"
  | E_delete (e) -> eprintf "E_delete("; print_expr e; eprintf ")"
  | E_fcall (f, l) -> eprintf "E_fcall(%s, %d)" f (List.length l)
  | E_arracc (e1, e2) -> eprintf "E_arracc("; print_expr e1; eprintf ", "; print_expr e2; eprintf ")"
  | E_brack (e) -> eprintf "E_brack("; print_expr e; eprintf ")"
  | E_TODO -> eprintf "E_TODO()"
and for_expr =  
    let open Printf in
    function
    | Some e -> print_expr e; eprintf ", "
    | _ -> ()
and for_label = 
    let open Printf in
    function
    | Some l -> eprintf "%s, " l
    | _ -> ()
and print_stmt = 
  let open Printf in
  function
  | S_NOP -> eprintf "S_NOP ()"
  | S_expr e -> eprintf "S_expr (";  print_expr e; eprintf ")"
  | S_block l -> eprintf "S_block ("; List.iter print_stmt l; eprintf ")"
  | S_if (e, s, None) -> eprintf "S_if ("; print_expr e; eprintf ","; print_stmt s; eprintf ")"
  | S_if (e, s1, Some s2) -> eprintf "S_if ("; print_expr e; eprintf ","; print_stmt s1; eprintf ","; print_stmt s2; eprintf ")"
  | S_for (o1, o2, o3, s, l) -> eprintf "S_for("; for_expr o1; for_expr o2; for_expr o3; print_stmt s; eprintf ", "; for_label l; eprintf ")"
  | S_cont l -> eprintf "S_cont(%s)" (label_str l)
  | S_break l -> eprintf "S_break(%s)" (label_str l)
  | S_ret None -> eprintf "S_ret()"
  | S_ret Some e -> eprintf "S_ret("; print_expr e; eprintf ")"
  | S_TODO -> eprintf "S_TODO()"
and print_body b =
  let F_body (d, s) = b in 
  Printf.eprintf "{ ";
  List.iter print_decl d;
  Printf.eprintf " ,";
  List.iter print_stmt s;
  Printf.eprintf "}"

and print_decl = 
  let open Printf in
  function
  | D_var (v, l) -> eprintf "D_var (%s, %d)" (vartype_str v) (List.length l)
  | D_fun (r, n, p) -> eprintf "D_fun (%s, %s, %n)" (rettype_str r) n (List.length p)  
  | D_fdef (r, n, p, b) -> eprintf "D_fdef (%s, %s, %d, " (rettype_str r) n (List.length p); 
                           print_body b; eprintf ")";
  | D_TODO -> eprintf "D_TODO ()" 

let print_ast t = 
  Printf.eprintf "\nAST: \n";
  List.iter print_decl t;
  Printf.eprintf "\n"


  