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
and ast_expr = (* Consider what to do with ( expr ). *)
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
  | E_brack of ast_expr 
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
  | None -> ""
  | Some s -> s
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

(*
  | E_tcast of vartype * ast_expr
  | E_ternary of ast_expr * ast_expr * ast_expr
  | E_new of vartype * ast_expr option 
  | E_delete of ast_expr
  | E_fcall of fname * ast_expr list  
  | E_arracc of ast_expr * ast_expr
  | E_brack of ast_expr 
  | E_TODO
*)
let rec print_expr e = 
  match e with 
  | E_var s -> Printf.eprintf "E_var(%s)\n" s
  | E_int i -> Printf.eprintf "E_var(%d)\n" i
  | E_char c -> Printf.eprintf "E_char(%c)\n" c
  | E_double d -> Printf.eprintf "E_var(%f)\n" d
  | E_str s -> Printf.eprintf "E_var(%s)\n" s
  | E_bool b when b -> Printf.eprintf "E_bool(True)\n"
  | E_bool b -> Printf.eprintf "E_bool(False)\n"
  | E_NULL -> Printf.eprintf "E_NULL()\n"
  | E_uop (op, e) -> Printf.eprintf "E_uop(%s,\n" (uop_str op); print_expr e; Printf.eprintf ")\n"
  | E_binop (e1, op, e2) -> Printf.eprintf "E_binop(\n"; print_expr e1; Printf.eprintf",%s, \n" (binop_str op); print_expr e2; Printf.eprintf ")\n"
  | E_uasgnpre (ua, e) -> Printf.eprintf "E_uasgnpre(%s,\n" (uassign_str op); print_expr e; Printf.eprintf ")\n"
  | E_uasgnpost (e, e) -> Printf.eprintf "E_uasgnpost(%s,\n" (uassign_str op); print_expr e; Printf.eprintf ")\n"
  | E_basgn (e1, op, e2) -> Printf.eprintf "E_binop(\n"; print_expr e1; Printf.eprintf",%s,\n" (bassign_str op); print_expr e2; Printf.eprintf ")\n"
  | _ -> Printf.eprintf "E_EXPR(*TODO*)\n"
and print_stmt s = 
  match s with (* Todo if, for *)
  | S_NOP -> Printf.eprintf "S_NOP ()\n"
  | S_expr e -> Printf.eprintf "S_expr (\n";  print_expr e; Printf.eprintf ")\n"
  | S_block l -> Printf.eprintf "S_block (\n"; List.iter print_stmt l; Printf.eprintf ")\n"
  | S_cont l -> Printf.eprintf "S_cont(%s)\n" (label_str l)
  | S_break l -> Printf.eprintf "S_break(%s)\n" (label_str l)
  | S_ret None -> Printf.eprintf "S_ret()\n"
  | S_ret Some e -> Printf.eprintf "S_ret(\n"; print_expr e; Printf.eprintf ")\n"
  | S_TODO -> Printf.eprintf "S_TODO()\n"
  | _ -> Printf.eprintf "S_STMT(*TODO*)\n"
and print_body b =
  let F_body (d, s) = b in 
  List.iter print_decl d;
  List.iter print_stmt s
and print_decl (d : ast_decl) = 
  match d with 
  | D_var (v, l) -> Printf.eprintf "D_var (%s, %d)\n" (vartype_str v) (List.length l)
  | D_fun (r, n, p) -> Printf.eprintf "D_fun (%s, %s, %n)\n" (rettype_str r) n (List.length p)  
  | D_fdef (r, n, p, b) -> Printf.eprintf "D_fdef (%s, %s, %d,\n" (rettype_str r) n (List.length p); 
                           print_body b; Printf.eprintf ")\n";
  | D_TODO -> Printf.eprintf "D_TODO ()\n" 

let print_ast t = 
  Printf.eprintf "\nAST: \n";
  List.iter print_decl t;

  