type var = string
type fname = string
type label = string
type uop = 
  | O_ref | O_dref | O_psgn | O_nsgn | O_neg
type binop = 
  | O_times | O_div | O_mod | O_plus | O_minus
  | O_lt | O_gt | O_le | O_ge | O_eq | O_neq 
  | O_and | O_or | O_comma
type uassign = 
  | O_plpl | O_mimi
type bassign = 
  | O_asgn | O_mulasgn | O_divasgn 
  | O_modasgn | O_plasgn | O_minasgn
type primitive = 
  | INT | CHAR | BOOL | DOUBLE 
and vartype = 
  | PTR of primitive * int
and rettype = 
  | VOID | RET of vartype
and parameter = 
  | BYREF of vartype * var 
  | BYVAL of vartype * var

type ast_decl = { decl : decl; meta : Lexing.position } 
and fdef_info = {rt : rettype; fn : fname; 
  p : parameter list; b : ast_body;
  mutable env : parameter list}
and decl =
  | D_var of vartype * (var * ast_expr option) list
  | D_fun of rettype * fname * parameter list  
  | D_fdef of fdef_info
and ast_body = 
  | F_body of ast_decl list * ast_stmt list
and ast_stmt = { stmt : stmt; meta : Lexing.position } 
and stmt =
  | S_NOP
  | S_expr of ast_expr
  | S_block of ast_stmt list
  | S_if of ast_expr * ast_stmt * ast_stmt option 
  | S_for of ast_expr option * ast_expr option 
            * ast_expr option * ast_stmt * label option
  | S_cont of label option 
  | S_break of label option
  | S_ret of ast_expr option
and ast_expr = { expr : expr; meta : Lexing.position }
and fcall_info = { fn : fname;  exprs : ast_expr list; 
  mutable mangl : fname } 
and expr = 
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
  | E_new of vartype * ast_expr
  | E_delete of ast_expr
  | E_fcall of fcall_info
  | E_arracc of ast_expr * ast_expr
  | E_brack of ast_expr

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

let rec print_expr e = 
  let open Printf in
  match e.expr with
  | E_var s -> printf "E_var(%s)" s
  | E_int i -> printf "E_int(%d)" i
  | E_char c -> printf "E_char(%c)" c
  | E_double d -> printf "E_double(%f)" d
  | E_str s -> printf "E_str(%s)" 
    (String.escaped s)
  | E_bool b -> printf "E_bool(%B)" b
  | E_NULL -> printf "E_NULL()"
  | E_uop (op, e) -> printf "E_uop(\"%s\"," 
    (uop_str op); print_expr e; printf ")"
  | E_binop (e1, op, e2) -> printf "E_binop("; 
    print_expr e1; printf ", \"%s\", " 
    (binop_str op); print_expr e2; printf ")"
  | E_uasgnpre (ua, e) -> printf "E_uasgnpre(\"%s\", "
    (uassign_str ua); print_expr e; printf ")"
  | E_uasgnpost (ua, e) -> printf "E_uasgnpost(\"%s\", " 
    (uassign_str ua); print_expr e; printf ")"
  | E_basgn (e1, op, e2) -> printf "E_basgn("; 
    print_expr e1; printf ", \"%s\", "  
    (bassign_str op); print_expr e2; printf ")"
  | E_tcast (v, e) -> printf "E_tcast(\"%s\", " 
    (vartype_str v); print_expr e;
  | E_ternary (e1, e2, e3) -> printf "E_ternary("; 
    print_expr e1; printf ", ";  print_expr e2; 
    printf ", "; print_expr e3; printf ")";
  | E_new (v, e) -> printf "E_new(%s" (vartype_str v);
    printf ", "; print_expr e; printf ")"
  | E_delete e -> printf "E_delete(";
    print_expr e; printf ")"
  | E_fcall r -> printf "E_fcall(%s, " r.fn;
    List.iter (fun s -> print_expr s; 
    printf " ," ) r.exprs; printf ")\n"
  | E_arracc (e1, e2) -> printf "E_arracc(";
    print_expr e1; printf ", "; 
    print_expr e2; printf ")"
  | E_brack e -> printf "E_brack("; 
    print_expr e; printf ")"
and for_expr =  
    let open Printf in
    function
    | Some e -> print_expr e; printf ", "
    | _ -> ()
and for_label = 
    let open Printf in
    function
    | Some l -> printf "%s, " l
    | _ -> ()
and print_stmt s = 
  let open Printf in
  match s.stmt with
  | S_NOP -> printf "S_NOP () "
  | S_expr e -> printf "S_expr("; 
    print_expr e; printf ") "
  | S_block s -> printf "S_block(";
    List.iter print_stmt s; printf ") "
  | S_if (e, s, None) -> printf "S_if(";
    print_expr e; printf ","; 
    print_stmt s; printf ") "
  | S_if (e, s1, Some s2) -> printf "S_if(";
    print_expr e; printf ","; 
    print_stmt s1; printf ","; 
    print_stmt s2; printf ") "
  | S_for (o1, o2, o3, s, l) -> printf "S_for(";
    for_expr o1; for_expr o2; 
    for_expr o3; print_stmt s; 
    printf ", "; for_label l; printf ") "
  | S_cont l -> printf "S_cont(%s) " (label_str l)
  | S_break l -> printf "S_break(%s) " (label_str l)
  | S_ret None -> printf "S_ret() "
  | S_ret Some e -> printf "S_ret(";
    print_expr e; printf ") "
and print_body b =
  let F_body (d, s) = b in 
  Printf.printf "{ ";
  List.iter print_decl d;
  Printf.printf ", ";
  List.iter print_stmt s;
  Printf.printf "}"

and print_decl d = 
  let open Printf in
  match d.decl with 
  | D_var (v, l) -> printf "D_var(%s, %d) " 
    (vartype_str v) (List.length l)
  | D_fun (r, n, p) -> printf "D_fun(%s, %s, %n)  "
    (rettype_str r) n (List.length p)  
  | D_fdef r -> printf "D_fdef(%s, %s, %d, " 
    (rettype_str r.rt) r.fn (List.length r.p); 
    print_body r.b; printf ") "

let print_ast t = 
  Printf.printf "\027[1;36mAST:\027[0m \n";
  List.iter print_decl t;
  Printf.printf "\n \n"