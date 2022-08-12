%{
    open Ast
%}

(* Token Declarations *)
%token T_eof 
%token <Ast.ast> T_include
%token <string> T_id 
%token T_int T_double 
       T_char T_bool T_void
%token <int> T_constint 
%token <float> T_constreal
%token <char> T_constchar 
%token <string> T_string 
%token T_false T_true
%token T_break T_continue  
%token T_byref  
%token T_new T_delete  
%token T_for  
%token T_if T_else 
%token T_NULL 
%token T_return  
%token T_assign 
%token T_eq T_neq T_gt
       T_lt T_ge T_le 
%token T_plus T_minus T_times
       T_div T_mod 
%token T_ref 
%token T_not T_and T_or 
%token T_question T_colon
       T_comma T_semicolon
%token T_plusplus T_minusminus 
%token T_plusequals T_minusequals 
       T_timesequals T_divequals 
       T_modequals
%token T_leftpar T_rightpar 
       T_leftsqbr T_rightsqbr 
       T_leftbr T_rightbr

(* Precedence & Associativity Declarations *)
%nonassoc LOW
%nonassoc T_else
%left  T_comma
%right T_assign T_plusequals T_minusequals 
       T_timesequals T_divequals T_modequals
%right T_question
%left T_or
%left T_and 
%nonassoc T_eq T_neq T_gt T_lt T_le T_ge 
%left T_plus T_minus 
%left T_times T_div T_mod 
%nonassoc T_leftpar 
%nonassoc T_plusplus T_minusminus
%nonassoc T_new T_delete
%nonassoc TUOP
%left T_leftsqbr  

(* Type declarations *)
%start program
%type <Ast.ast> program
%type <ast_stmt> statement
%type <ast_expr> expression
%type <ast_decl> declaration
%type <vartype> data_type
%type <rettype> result_data_type
%type <uop> unary_operator
%type <binop> binary_operator
%type <uassign> unary_assignment
%type <bassign> binary_assignment

%% /* Grammar rules and actions follow */

program: 
        | nonempty_list(line) T_eof { List.flatten $1 } // Maybe find a more efficient way of writing?

line:
        | declaration { [$1] } // Don't quite like that
        | T_include   { $1 }
;

declaration:  
        | variable_declaration   { $1 }
        | function_declaration   { $1 }
        | function_definition    { $1 }       
;

variable_declaration: 
        | data_type separated_nonempty_list(T_comma, declarator) T_semicolon   { { decl =  D_var ($1, $2); 
                                                                                   meta =Lexing.dummy_pos } }
;

pointer:
        | T_times pointer { $2 + 1 }
        | %prec LOW { 0 }

data_type: 
        | basic_data_type pointer { PTR ($1, $2) }
;

%inline basic_data_type:
        | T_int      { INT }
        | T_char     { CHAR }
        | T_bool     { BOOL }
        | T_double   { DOUBLE }
;

declarator: 
        | T_id option(bracketed_const_expression)    { ($1, $2) }
;

bracketed_const_expression:
        | T_leftsqbr const_expression T_rightsqbr { $2 }
;

function_declaration: 
        | result_data_type T_id T_leftpar separated_list(T_comma, parameter) T_rightpar T_semicolon   { { decl = D_fun ($1, $2, $4);
                                                                                                          meta = $symbolstartpos } }
;

%inline function_header:                                                 
        | result_data_type T_id T_leftpar separated_list(T_comma, parameter) T_rightpar { ($1, $2, $4) }
;

%inline function_body:  
        | T_leftbr list(declaration) list(statement) T_rightbr { F_body ($2, $3) } 
;

%inline result_data_type:
        | data_type { RET $1 }
        | T_void    { VOID }
;

parameter:
        | option(T_byref) data_type T_id     { match $1 with
                                               | None -> BYVAL ($2, $3)
                                               | _ -> BYREF ($2, $3) }
;

function_definition: 
        | function_header function_body   { let (r, f, p) = $1 in 
                                            { decl = D_fdef (r, f, p, $2);
                                              meta =$symbolstartpos } }
;

statement:
        | T_semicolon                                                                         { { stmt = S_NOP;
                                                                                                  meta = $symbolstartpos } } 
        | expression T_semicolon                                                              { { stmt = S_expr $1;
                                                                                                  meta = $symbolstartpos } } 
        | T_leftbr list(statement) T_rightbr                                                  { { stmt = S_block $2;
                                                                                                  meta = $symbolstartpos } } 
        | T_if T_leftpar expression T_rightpar statement                          %prec LOW   { { stmt = S_if ($3, $5, None);
                                                                                                  meta = $symbolstartpos } } 
        | T_if T_leftpar expression T_rightpar statement T_else statement                     { { stmt = S_if ($3, $5, Some $7); 
                                                                                                  meta = $symbolstartpos } }
        | T_for for_control statement                                                         { let (a, b, c) = $2 in
                                                                                                { stmt = S_for (a, b, c, $3, None);
                                                                                                  meta = $symbolstartpos } } 
        | T_id T_colon T_for for_control statement                                            { let (a, b, c) = $4 in
                                                                                                { stmt = S_for (a, b, c, $5, Some $1);
                                                                                                  meta = $symbolstartpos } }
        | T_continue option(T_id) T_semicolon                                                 { { stmt = S_cont $2; 
                                                                                                  meta = $symbolstartpos } } 
        | T_break option(T_id) T_semicolon                                                    { { stmt = S_break $2;
                                                                                                  meta = $symbolstartpos } } 
        | T_return option(expression) T_semicolon                                             { { stmt = S_ret $2; 
                                                                                                  meta = $symbolstartpos } }
;

%inline for_control:
        | T_leftpar option(expression) T_semicolon option(expression) T_semicolon option(expression) T_rightpar   { let e = { expr = E_bool true; 
                                                                                                                              meta = $startpos($4) } 
                                                                                                                    in match $4 with 
                                                                                                                    | None -> ($2, Some e, $6)
                                                                                                                    | _ -> ($2, $4, $6) 
                                                                                                                  }         
;

expression:
        | T_id                                                                    { { expr = E_var $1;
                                                                                      meta = $symbolstartpos } }
        | T_leftpar expression T_rightpar                                         { { expr = E_brack $2;
                                                                                      meta = $symbolstartpos } } // Bracketed expression
        | T_true                                                                  { { expr = E_bool true;
                                                                                      meta = $symbolstartpos } }
        | T_false                                                                 { { expr = E_bool false; 
                                                                                      meta = $symbolstartpos } }
        | T_NULL                                                                  { { expr = E_NULL; 
                                                                                      meta = $symbolstartpos } } 
        | T_constint                                                              { { expr = E_int $1;
                                                                                      meta = $symbolstartpos } }
        | T_constchar                                                             { { expr = E_char $1;
                                                                                      meta = $symbolstartpos } } 
        | T_constreal                                                             { { expr = E_double $1;
                                                                                      meta = $symbolstartpos } }
        | T_string                                                                { { expr = E_str $1;
                                                                                      meta = $symbolstartpos } }
        | T_id T_leftpar option(expression) T_rightpar                            { let exp = match $3 with
                                                                                    | None -> E_fcall ($1, [])
                                                                                    | Some e -> 
                                                                                        let rec flatten ex acc =
                                                                                            match ex.expr with
                                                                                            | E_binop (x, O_comma, y) -> flatten x (y :: acc)
                                                                                            | _ -> ex :: acc
                                                                                        in E_fcall ($1, flatten e [])
                                                                                    in { expr = exp; meta = $symbolstartpos }
                                                                                  } // Comma is left associative.
        | expression T_leftsqbr expression T_rightsqbr                            { { expr = E_arracc ($1, $3); 
                                                                                      meta = $symbolstartpos } } 
        | unary_operator expression                             %prec TUOP        { { expr = E_uop ($1, $2); 
                                                                                      meta = $symbolstartpos } }
        | expression binary_operator expression                                   { { expr = E_binop ($1, $2, $3); 
                                                                                      meta = $symbolstartpos } }
        | unary_assignment expression                                             { { expr = E_uasgnpre ($1, $2); 
                                                                                      meta = $symbolstartpos } }
        | expression unary_assignment                                             { { expr = E_uasgnpost ($2, $1); 
                                                                                      meta = $symbolstartpos } }
        | expression binary_assignment expression                                 { { expr = E_basgn ($1, $2, $3); 
                                                                                      meta = $symbolstartpos } }
        | T_leftpar data_type T_rightpar expression             %prec T_leftpar   { { expr = E_tcast ($2, $4); 
                                                                                      meta = $symbolstartpos } } 
        | expression T_question expression T_colon expression   %prec T_question  { { expr = E_ternary ($1, $3, $5); 
                                                                                      meta = $symbolstartpos } } 
        | dynamic_allocation                                                      { $1 } 
        | T_delete expression                                                     { { expr = E_delete $2; 
                                                                                      meta = $symbolstartpos } }
; 


dynamic_allocation:
        | T_new data_type T_leftsqbr expression T_rightsqbr   { { expr = E_new ($2, $4); 
                                                                  meta = $symbolstartpos } }
        | T_new data_type { let e = { expr = E_int 1; 
                                      meta = $endpos } 
                            in { expr = E_new ($2, e); 
                                 meta = $symbolstartpos } }
;

const_expression:
        | expression   { $1 } // Do we need something more implicit for constant expressions?
;

%inline unary_operator:
        | T_ref     { O_ref }    
        | T_times   { O_dref }
        | T_plus    { O_psgn }
        | T_minus   { O_nsgn }
        | T_not     { O_neg }
;

%inline binary_operator:
        | T_times   { O_times }
        | T_div     { O_div }
        | T_mod     { O_mod }
        | T_plus    { O_plus }
        | T_minus   { O_minus }
        | T_lt      { O_lt }
        | T_gt      { O_gt }
        | T_le      { O_le } 
        | T_ge      { O_ge }
        | T_eq      { O_eq } 
        | T_neq     { O_neq } 
        | T_and     { O_and } 
        | T_or      { O_or } 
        | T_comma   { O_comma }
;

%inline unary_assignment:
        | T_plusplus     { O_plpl }
        | T_minusminus   { O_mimi }
;

%inline binary_assignment:
        | T_assign        { O_asgn }      
        | T_timesequals   { O_mulasgn } 
        | T_divequals     { O_divasgn  }
        | T_modequals     { O_modasgn }
        | T_plusequals    { O_plasgn }
        | T_minusequals   { O_minasgn }
;

%%
