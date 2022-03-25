
%%

/* One declaration at least */
program: 
          declaration declaration_list T_eof { () }

declaration_list:  
          /* No more declarations */     { () }
        | declaration declaration_list   { () }

declaration:  
          var_declaration   { () }
        | fun_declaration   { () }
        | fun_definition    { () }       

var_declaration: 
          type declarator declarator_list T_semicolon { () }

declarator_list:  
          /* No more declarators */               { () }
        | T_comma declarator declarator_list     { () }

type: 
          basic_type point_list { () }

point_list: 
          /* No more asterisks */   { () }
        | T_times point_list        { () }

basic_type:
          T_int      { () }
        | T_char     { () }
        | T_bool     { () }
        | T_double   { () }

declarator: 
          T_id                                          { () }
        | T_id T_leftsqbr const_expression T_rightsqbr  { () }

fun_header: // parameter_list should be optional. It is not currently. 
          result_type T_id T_leftpar parameter_list T_rightpar  { () }

fun_declaration: 
          fun_header T_semicolon    { () }

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

fun_definition: 
          fun_header fun_body   { () }

fun_body:
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
          T_for 
          
continue:
          T_continue            { () } 
        | T_continue T_id       { () } 

break:
          T_break         { () } 
        | T_break T_id    { () } 

return:
          T_return expression     { () } 

if_statement:
          T_if bracketed_expression statement                       { () } 
        | T_if bracketed_expression statement T_else statement      { () } 

bracketed_expression:
          T_leftpar expression T_rightpar        { () }

expression:
          T_id
        | bracketed_expression
        | T_true
        | T_false
        | T_NULL
        | T_constint 
        | T_constchar 
        | T_constreal
        | T_string  
        | T_id T_leftpar expression_list T_rightpar 
        | expression T_leftsqbr expression T_rightsqbr
        | unary_operator expression
        | expression binary_operator expression
        | unary_assignment expression
        | expression unary_assignment
        | expression binary_assignment expression
        | T_leftpar type T_rightpar expression
        | expression T_question expression T_colon expression
        | dynamic_allocation
        | T_delete expression

dynamic_allocation:
          T_new type 
        | T_new type T_leftsqbr expression T_rightsqbr 

expression_list:
          expression expression_trail

expression_trail:
          /* No more expressions */
        | T_comma expression expression_trail

const_expression:
          expression

unary_operator:
          T_ref 
        | T_times
        | T_plus
        | T_minus
        | T_not 

binary_operator:
          T_times
        | T_div 
        | T_mod
        | T_plus 
        | T_minus 
        | T_lt 
        | T_gt
        | T_le 
        | T_ge 
        | T_eq 
        | T_neq 
        | T_and 
        | T_or 
        | T_comma 

unary_assignment:
          T_plusplus
        | T_minusminus

binary_assignment:
          T_assign 
        | T_plusequals
        | T_divequals 
        | T_modequals
        | T_timesequals 
        | T_minusequals 
              
          




