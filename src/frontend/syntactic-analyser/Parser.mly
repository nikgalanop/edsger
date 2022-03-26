%token T_eof 
%token T_id 
%token T_constint 
%token T_constreal
%token T_constchar 
%token T_string  
%token T_bool  
%token T_break  
%token T_byref  
%token T_char 
%token T_continue  
%token T_delete  
%token T_double  
%token T_else
%token T_for  
%token T_false  
%token T_if  
%token T_int  
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

%start program
%%
program: 
          declaration declaration_list T_eof   { () }

declaration_list:  
          /* No more declarations */     { () }
        | declaration declaration_list   { () }

declaration:  
          variable_declaration   { () }
        | function_declaration   { () }
        | function_definition    { () }       

variable_declaration: 
          type declarator declarator_list T_semicolon   { () }

declarator_list:  
          /* No more declarators */              { () }
        | T_comma declarator declarator_list     { () }

type: 
          basic_type pointer_list    { () }

pointer_list: 
          /* No more asterisks */     { () }
        | T_times pointer_list        { () }

basic_type:
          T_int      { () }
        | T_char     { () }
        | T_bool     { () }
        | T_double   { () }

declarator: 
          T_id                                            { () }
        | T_id T_leftsqbr const_expression T_rightsqbr    { () }

function_declaration: 
          function_header T_semicolon    { () }

function_header: 
          result_type T_id T_leftpar T_rightpar                 { () }
        | result_type T_id T_leftpar parameter_list T_rightpar  { () }

result_type:
          type      { () }
        | T_void    { () }

parameter_list:     
        parameter parameter_trail   { () }

parameter_trail:   
          /* No more parameters */              { () }
        | T_comma  parameter parameter_trail    { () }

parameter:
          type T_id             { () }
        | T_byref type T_id     { () }

function_definition: 
          function_header function_body   { () }

function_body:
          T_leftbr  declaration_list statement_list T_rightbr    { () } 

statement_list:
          /* No more statements */     { () } 
        | statement statement_list     { () } 
          
statement:
          T_semicolon                           { () } 
        | expression T_semicolon                { () } 
        | T_leftbr statement_list T_rightbr     { () } 
        | if_statement                          { () }
        | for_statement                         { () } 
        | continue T_semicolon                  { () } 
        | break T_semicolon                     { () } 
        | return T_semicolon                    { () } 

for_statement:
          unlabeled_for     { () }
        | labeled_for       { () }

unlabeled_for:
          T_for for_control statement    { () }

for_control:
         T_leftpar for_expression for_expression optional_expression T_rightpar   { () }         

for_expression:
         optional_expression T_semicolon  { () }

labeled_for:
         T_id T_colon unlabeled_for     { () }

optional_expression:
          /* No expression */   { () }
        | expression            { () }

continue:
          T_continue            { () } 
        | T_continue T_id       { () } 

break:
          T_break         { () } 
        | T_break T_id    { () } 

return:
          T_return                { () }      
        | T_return expression     { () } 

if_statement:
          T_if bracketed_expression statement                       { () } 
        | T_if bracketed_expression statement T_else statement      { () } 

bracketed_expression:
          T_leftpar expression T_rightpar        { () }

expression:
          T_id                                                  { () }
        | bracketed_expression                                  { () }
        | T_true                                                { () }
        | T_false                                               { () }
        | T_NULL                                                { () }
        | T_constint                                            { () }
        | T_constchar                                           { () }
        | T_constreal                                           { () }
        | T_string                                              { () }
        | function_call                                         { () }
        | expression T_leftsqbr expression T_rightsqbr          { () }
        | unary_operator expression                             { () }
        | expression binary_operator expression                 { () }
        | unary_assignment expression                           { () }
        | expression unary_assignment                           { () }
        | expression binary_assignment expression               { () }
        | T_leftpar type T_rightpar expressionc                 { () }
        | expression T_question expression T_colon expression   { () }
        | dynamic_allocation                                    { () }
        | T_delete expression                                   { () }

function_call:
          T_id T_leftpar T_rightpar                   { () }
        | T_id T_leftpar expression_list T_rightpar   { () }

dynamic_allocation:
          T_new type                                     { () }
        | T_new type T_leftsqbr expression T_rightsqbr   { () }

expression_list:
          expression expression_trail   { () }

expression_trail:
          /* No more expressions */             { () }
        | T_comma expression expression_trail   { () }

const_expression:
          expression   { () }

unary_operator:
          T_ref     { () }    
        | T_times   { () }
        | T_plus    { () }
        | T_minus   { () }
        | T_not     { () }

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

unary_assignment:
          T_plusplus     { () }
        | T_minusminus   { () }

binary_assignment:
          T_assign        { () }      
        | T_timesequals   { () } 
        | T_divequals     { () }
        | T_modequals     { () }
        | T_plusequals    { () }
        | T_minusequals   { () }