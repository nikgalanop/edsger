// %token T_eof
%token T_id 
%token <int>    T_int T_constint 
%token <float>  T_real T_constreal
%token <char>   T_char T_constchar 
%token <string> T_string  
%token <bool>   T_bool  
%token T_break  
%token T_byref  
%token T_continue  
%token T_delete  
%token T_double  
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

%left T_or
%left T_and 
%nonassoc T_eq T_neq T_gt T_lt T_le T_ge 
%left T_plus T_minus 
%left T_times T_div T_mod 

/* Type conversion has this precedence [()] */

%nonassoc T_plusplus T_minusminus
%nonassoc T_new T_delete

/* 
 * Same "symbol" for different operators. How do we face that. 
 * https://www.gnu.org/software/bison/manual/html_node/Contextual-Precedence.html 
 */

%start program
%type <unit> program

%% /* Grammar rules and actions follow */

program: 
          declarator declaration_list     { () }
;

declaration_list:  
          /* No more declarations */      { () }
        | declaration_list declaration    { () }
;

declaration:  
          variable_declaration   { () }
        | function_declaration   { () }
        | function_definition    { () }       
;

variable_declaration: 
          type declarator_list T_semicolon   { () }
;

declarator_list:  /* One declarator at least */
          declarator                             { () }
        | declarator_list T_comma declarator     { () }
;

type: 
          basic_type pointer_list    { () }
;

pointer_list: 
          /* No more asterisks */     { () }
        | pointer_list T_times        { () }
;

basic_type:
          T_int      { () }
        | T_char     { () }
        | T_bool     { () }
        | T_double   { () }
;

declarator: 
          T_id                                            { () }
        | T_id T_leftsqbr const_expression T_rightsqbr    { () }
;

function_declaration: 
          result_type T_id T_leftpar T_rightpar T_semicolon                  { () }
        | result_type T_id T_leftpar parameter_list T_rightpar T_semicolon   { () }
;

function_header: 
          result_type T_id T_leftpar T_rightpar                 { () }
        | result_type T_id T_leftpar parameter_list T_rightpar  { () }
;

result_type:
          type      { () }
        | T_void    { () }
;

parameter_list:  /* One parameter at least */
          parameter                             { () }
        | parameter_list T_comma parameter      { () }
;

parameter:
          type T_id             { () }
        | T_byref type T_id     { () }
;

function_definition: 
          function_header function_body   { () }
;

function_body:
          T_leftbr declaration_list statement_list T_rightbr    { () } 
;

statement_list:
          /* No more statements */     { () } 
        | statement_list statement     { () } 
;

statement:
          T_semicolon                           { () } 
        | expression T_semicolon                { () } 
        | T_leftbr statement_list T_rightbr     { () } 
        | T_if T_leftpar expression T_rightpar statement                       { () } 
        | T_if T_leftpar expression T_rightpar statement T_else statement      { () } 
        | T_for for_control statement
        | T_id T_colon T_for for_control statement
        | T_continue T_semicolon                { () } 
        | T_continue T_id T_semicolon           { () } 
        | T_break T_semicolon                   { () } 
        | T_break T_id T_semicolon              { () } 
        | T_return T_semicolon                    { () } 
        | T_return expression T_semicolon       { () }
;

for_control:
         T_leftpar optional_expression T_semicolon optional_expression T_semicolon  optional_expression T_rightpar   { () }         
;

optional_expression:
          /* No expression */             { () }
        | expression                      { () }
;

expression:
          T_id                                                  { () }
        | T_leftpar expression T_rightpar                                  { () }
        | T_true                                                { () }
        | T_false                                               { () }
        | T_NULL                                                { () }
        | T_constint                                            { () }
        | T_constchar                                           { () }
        | T_constreal                                           { () }
        | T_string                                              { () }
        | T_id T_leftpar T_rightpar                   { () }
        | T_id T_leftpar expression_list T_rightpar   { () }
        | expression T_leftsqbr expression T_rightsqbr          { () }
        | unary_operator expression                             { () }
        | expression binary_operator expression                 { () }
        | unary_assignment expression                           { () }
        | expression unary_assignment                           { () }
        | expression binary_assignment expression               { () }
        | T_leftpar type T_rightpar expression                  { () }
        | expression T_question expression T_colon expression   { () }
        | dynamic_allocation                                    { () }
        | T_delete expression                                   { () }
;

dynamic_allocation:
          T_new type                                     { () }
        | T_new type T_leftsqbr expression T_rightsqbr   { () }
;

expression_list: /* At least one expression */
          expression                           { () }
        | expression_list T_comma expression   { () }
;

const_expression:
          expression   { () }
;

unary_operator:
          T_ref     { () }    
        | T_times   { () }
        | T_plus    { () }
        | T_minus   { () }
        | T_not     { () }
;

binary_operator:
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

unary_assignment:
          T_plusplus     { () }
        | T_minusminus   { () }
;

binary_assignment:
          T_assign        { () }      
        | T_timesequals   { () } 
        | T_divequals     { () }
        | T_modequals     { () }
        | T_plusequals    { () }
        | T_minusequals   { () }
;