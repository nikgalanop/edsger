%token T_eof
%token T_id 
%token T_int T_constint 
%token T_double T_constreal
%token T_char T_constchar 
%token T_string  
%token T_bool  
%token T_break  
%token T_byref  
%token T_continue  
%token T_delete  
%token T_else
%token T_for  
%token T_false  
%token T_if  
%token T_new 
%token T_NULL 
%token T_return  
%token T_true  
%token T_void
%token T_assign 
%token T_eq 
%token T_neq 
%token T_gt
%token T_lt 
%token T_ge 
%token T_le 
%token T_plus 
%token T_minus 
%token T_times
%token T_div 
%token T_mod 
%token T_ref 
%token T_not 
%token T_and
%token T_or 
%token T_question 
%token T_colon 
%token T_comma 
%token T_plusplus 
%token T_minusminus 
%token T_plusequals
%token T_minusequals 
%token T_timesequals 
%token T_divequals 
%token T_modequals
%token T_semicolon 
%token T_leftpar 
%token T_rightpar 
%token T_leftsqbr 
%token T_rightsqbr 
%token T_leftbr 
%token T_rightbr

%left T_comma
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
%nonassoc T_leftpar

%nonassoc T_plusplus T_minusminus
%nonassoc T_new T_delete

/* 
 * Same "symbol" for different operators. How do we face that. 
 * https://www.gnu.org/software/bison/manual/html_node/Contextual-Precedence.html 
 */
%nonassoc TUOP
%nonassoc TUAPOST
%left T_leftsqbr TFUNC  // Rethink associativity of these "tokens"

%start <unit> program

%% /* Grammar rules and actions follow */

program: 
          nonempty_list(declaration) T_eof { () }

declaration:  
          variable_declaration   { () }
        | function_declaration   { () }
        | function_definition    { () }       
;

variable_declaration: 
          data_type separated_nonempty_list(T_comma, declarator) T_semicolon   { () }
;

data_type: 
          basic_data_type list(T_times) { () }
;

%inline basic_data_type:
          T_int      { () }
        | T_char     { () }
        | T_bool     { () }
        | T_double   { () }
        
;

declarator: 
          T_id option(bracketed_const_expression)    { () }
;

bracketed_const_expression:
          T_leftsqbr const_expression T_rightsqbr { () }
;

function_declaration: 
          result_data_type T_id T_leftpar separated_list(T_comma, parameter) T_rightpar T_semicolon   { () }
;

%inline function_header:                                                 
          result_data_type T_id T_leftpar separated_list(T_comma, parameter) T_rightpar { () }
;

%inline function_body:
          T_leftbr list(declaration) list(statement) T_rightbr    { () } 
;

%inline result_data_type:
          data_type { () }
        | T_void    { () }
;

parameter:
          option(T_byref) data_type T_id     { () }
;

function_definition: 
          function_header function_body   { () }
;

statement:
          T_semicolon                                                                         { () } 
        | expression T_semicolon                                                              { () } 
        | T_leftbr list(statement) T_rightbr                                                  { () } 
        | T_if T_leftpar expression T_rightpar statement                                      { () } 
        | T_if T_leftpar expression T_rightpar statement T_else statement                     { () }  
        | T_for for_control statement                                                         { () }
        | T_id T_colon T_for for_control statement                                            { () }
        | T_continue option(T_id) T_semicolon                                                 { () } 
        | T_break option(T_id) T_semicolon                                                    { () } 
        | T_return option(expression) T_semicolon                                             { () }
;

%inline for_control:
         T_leftpar option(expression) T_semicolon option(expression) T_semicolon  option(expression) T_rightpar   { () }         
;

expression:
          T_id                                                                    { () }
        | T_leftpar expression T_rightpar                                         { () }
        | T_true                                                                  { () }
        | T_false                                                                 { () }
        | T_NULL                                                                  { () }
        | T_constint                                                              { () }
        | T_constchar                                                             { () }
        | T_constreal                                                             { () }
        | T_string                                                                { () }
        | T_id T_leftpar option(expression) T_rightpar             %prec TFUNC    { () } // PROBLEMATIC!!!!!
        | expression T_leftsqbr expression T_rightsqbr                            { () }
        | unary_operator expression                             %prec TUOP        { () }
        | expression binary_operator expression                                   { () }
        | unary_assignment expression                                             { () }
        | expression unary_assignment                           %prec TUAPOST     { () }
        | expression binary_assignment expression                                 { () }
        | T_leftpar data_type T_rightpar expression             %prec T_leftpar   { () } // Not sure
        | expression T_question expression T_colon expression   %prec T_question  { () } // Not sure
        | T_new data_type option(array_allocation)              %prec T_new       { () } // Not sure
        | T_delete expression                                                     { () }
; 

array_allocation:
          T_leftsqbr expression T_rightsqbr   { () }
;

const_expression:
          expression   { () }
;

%inline unary_operator:
          T_ref     { () }    
        | T_times   { () }
        | T_plus    { () }
        | T_minus   { () }
        | T_not     { () }
;

%inline binary_operator:
          T_times   { () }
        | T_div     { () }
        | T_mod     { () }
        | T_plus    { () }
        | T_minus   { () }
        | T_lt      { () }
        | T_gt      { () }
        | T_le      { () } 
        | T_ge      { () }
        | T_eq      { () } 
        | T_neq     { () } 
        | T_and     { () } 
        | T_or      { () } 
        | T_comma   { () }
;

%inline unary_assignment:
          T_plusplus     { () }
        | T_minusminus   { () }
;

%inline binary_assignment:
          T_assign        { () }      
        | T_timesequals   { () } 
        | T_divequals     { () }
        | T_modequals     { () }
        | T_plusequals    { () }
        | T_minusequals   { () }
;