(* Header Section *)

{
    type token = 
        T_eof  
        
        (* Keywords *)
        (* bool break byref char continue delete
           double else for false if int
           new NULL return true void *)

        | T_bool  | T_break  | T_byref  | T_char 
        | T_continue  | T_delete  | T_double  | T_else
        | T_for  | T_false  | T_if  | T_int  | T_new 
        | T_NULL | T_return  | T_true  | T_void
        
        (* Symbolic Operators *)
        (*  = == != > < >= <=
            + − * / % & !
            && || ? : , ++ −−
            += −= *= /= %=  *)

        | T_assign | T_eq | T_neq | T_gt | T_lt | 
        | T_ge | T_le | T_plus | T_minus | T_times
        | T_div | T_mod | T_ref | T_not | T_and
        | T_or | T_question | T_colon | T_comma 
        | T_plusplus | T_minusminus | T_plusequals
        | T_minusequals | T_timesequals | T_divequals 
        | T_modequals

        (* Seperators *)
        (* ; ( ) [ ] { } *)

        | T_semicolon | T_leftpar | T_rightpar | T_leftsqbr 
        | T_rightsqbr | T_leftbr | T_rightbr
}

(* Definitions Section *)

let digit = ['0'-'9'];
let letter = ['a'-'z''A'-'Z'];
let whitespace = [' ''\n''\t'];


(* Rules Section *)

rule lexer = parse 
    
    (* Keywords *)

      "bool"        { T_bool }
    | "break"       { T_break }
    | "byref"       { T_byref }
    | "char"        { T_char }
    | "continue"    { T_continue }
    | "delete"      { T_delete }
    | "double"      { T_double }
    | "else"        { T_else }
    | "for"         { T_for }
    | "false"       { T_false }
    | "if"          { T_if }
    | "int"         { T_int }
    | "new"         { T_new }
    | "NULL"        { T_NULL }
    | "return"      { T_return }
    | "true"        { T_true }
    | "void"        { T_void }

    (* Symbolic Operators *)

    | "="           { T_assign }
    | "=="          { T_eq }
    | "!="          { T_neq }
    | ">"           { T_gt }
    | "<"           { T_lt }
    | ">="          { T_ge }
    | "<="          { T_le }
    | "+"           { T_plus }
    | "-"           { T_minus }
    | "*"           { T_times }
    | "/"           { T_div }
    | "%"           { T_mod }
    | "&"           { T_ref }
    | "!"           { T_not }
    | "&&"          { T_and }
    | "||"          { T_or }
    | "?"           { T_question }
    | ":"           { T_colon }
    | ","           { T_comma }
    | "++"          { T_plusplus }
    | "--"          { T_minusminus }
    | "+="          { T_plusequals }
    | "-="          { T_minusequals }
    | "*="          { T_timesequals }
    | "/="          { T_divequals }
    | "%="          { T_modequals }
    
    (* Seperators *)

    | ";"           { T_semicolon }
    | "("           { T_leftpar }
    | ")"           { T_rightpar }
    | "["           { T_leftsqbr }
    | "]"           { T_rightsqbr }
    | "{"           { T_leftbr }
    | "}"           { T_rightbr }

    (* Rest *)

    | whitespace+   { lexer lexbuf } (* Ignore all whitespaces *)

(* Trailer Section *)

{

}