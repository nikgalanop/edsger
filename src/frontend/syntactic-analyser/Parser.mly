%{
        open Ast
%}

(* Token Declarations *)
%token T_eof T_include
%token T_id 
%token T_int T_constint 
%token T_double T_constreal
%token T_char T_constchar 
%token T_string  
%token T_bool  
%token T_break T_continue  
%token T_byref  
%token T_new T_delete  
%token T_for  
%token T_false  
%token T_if T_else 
%token T_NULL 
%token T_return  
%token T_true  
%token T_void
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
/* 
 * Ternary operator has this precedence [?:]
 * Paragraph 4.2.1: http://cambium.inria.fr/~fpottier/menhir/manual.html 
 */
%left T_question
%left T_or
%left T_and 
%nonassoc T_eq T_neq T_gt T_lt T_le T_ge 
%left T_plus T_minus 
%left T_times T_div T_mod 
/* Type conversion has this precedence [()] */
%nonassoc T_leftpar // Check this again
%nonassoc T_plusplus T_minusminus
%nonassoc T_new T_delete
/* 
 * Same "symbol" for different operators. How do we face that. 
 * https://www.gnu.org/software/bison/manual/html_node/Contextual-Precedence.html 
 */ 
%nonassoc TUOP
%left T_leftsqbr  // Rethink associativity of these "tokens"

(* Type declarations *)
%start program
%type <ast_stmt list> program
%type <ast_stmt> statement
%type <ast_expr> expression
%type <vartype> data_type
%type <rettype> result_data_type
// Add the types of T_constint etc.
%% /* Grammar rules and actions follow */

program: 
        | nonempty_list(line) T_eof { $1 }

line:
        | declaration { $1 }
        | T_include   { S_TODO }
;

declaration:  
        | variable_declaration   { $1 }
        | function_declaration   { $1 }
        | function_definition    { $1 }       
;

variable_declaration: 
        | data_type separated_nonempty_list(T_comma, declarator) T_semicolon   { D_var ($1, $2) }
;

pointer:
        | T_times pointer { $2 + 1 }
        | %prec LOW { 0 }

data_type: 
        | basic_data_type pointer { PTR $1 $2 }
;

%inline basic_data_type:
        | T_int      { INT }
        | T_char     { CHAR }
        | T_bool     { BOOL }
        | T_double   { DOUBLE }
;

declarator: 
        | T_id option(bracketed_const_expression)    { ($1, $2) } // Should somehow "remember" if var is an array or not.
;

bracketed_const_expression:
        | T_leftsqbr const_expression T_rightsqbr { $2 }
;

function_declaration: 
        | result_data_type T_id T_leftpar separated_list(T_comma, parameter) T_rightpar T_semicolon   { () }
;

%inline function_header:                                                 
        | result_data_type T_id T_leftpar separated_list(T_comma, parameter) T_rightpar { ($2, $1, $4) }
;

%inline function_body:
        | T_leftbr list(declaration) list(statement) T_rightbr { F_body ($2, $3) } 
;

%inline result_data_type:
        | data_type { RET $1 }
        | T_void    { VOID }
;

parameter:
        | option(T_byref) data_type T_id     { 
                                               match $1 with
                                               | None -> BYVAL $2 $3
                                               | _ -> BYREF $2 $3  
                                              }
;

function_definition: 
        | function_header function_body   { 
                                            let (f, r, p) = $1 in 
                                            D_fdef (f, r, p, $2) 
                                          }
;

statement:
        | T_semicolon                                                                         { S_NOP } 
        | expression T_semicolon                                                              { S_expr $1 } 
        | T_leftbr list(statement) T_rightbr                                                  { S_TODO } 
        | T_if T_leftpar expression T_rightpar statement                          %prec LOW   { S_if ($3, $5, None) } 
        | T_if T_leftpar expression T_rightpar statement T_else statement                     { S_if ($3, $5, Some $7) }
        | T_for for_control statement                                                         { S_TODO } // Will need some pattern matching
        | T_id T_colon T_for for_control statement                                            { S_TODO } //      <<      <<       << 
        | T_continue option(T_id) T_semicolon                                                 { S_cont $2 } 
        | T_break option(T_id) T_semicolon                                                    { S_break $2 } 
        | T_return option(expression) T_semicolon                                             { S_ret $2 }
;

%inline for_control:
        | T_leftpar option(expression) T_semicolon option(expression) T_semicolon option(expression) T_rightpar   { () }         
;

expression:
        | T_id                                                                    { E_var $1 }
        | T_leftpar expression T_rightpar                                         { E_TODO } // Bracketed expression
        | T_true                                                                  { E_bool true }
        | T_false                                                                 { E_bool false }
        | T_NULL                                                                  { E_NULL } // Null
        | T_constint                                                              { E_int $1 }
        | T_constchar                                                             { E_char $1 } 
        | T_constreal                                                             { E_double $1 }
        | T_string                                                                { E_str $1 }
        | T_id T_leftpar option(expression) T_rightpar                            { E_TODO } // Function call
        | expression T_leftsqbr expression T_rightsqbr                            { E_TODO } // Array access
        | unary_operator expression                             %prec TUOP        { E_uop ($1, $2) }
        | expression binary_operator expression                                   { E_binop ($1, $2, $3) }
        | unary_assignment expression                                             { E_uasgnpre ($1, $2) }
        | expression unary_assignment                                             { E_uasgnpost ($1, $2) }
        | expression binary_assignment expression                                 { E_basgn ($1, $2, $3) }
        | T_leftpar data_type T_rightpar expression             %prec T_leftpar   { E_TODO } // Typecasting
        | expression T_question expression T_colon expression   %prec T_question  { E_ternary ($1, $3, $5) } 
        | dynamic_allocation                                                      { E_TODO } // Dynamic Allocation
        | T_delete expression                                                     { E_TODO } //   <<   Deallocation
; 

dynamic_allocation:
        | T_new data_type T_leftsqbr expression T_rightsqbr   { E_TODO }
        | T_new data_type { E_TODO }
;

const_expression:
        | expression   { E_const $1 }
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
        | T_modequals     { O_modasng }
        | T_plusequals    { O_plasgn }
        | T_minusequals   { O_minasgn }
;

%%
