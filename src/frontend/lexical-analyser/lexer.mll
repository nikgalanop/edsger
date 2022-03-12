(* To-do? *)
(* Test whatever I've written up to this version. *)
(* Character constants and strings? *)
(* Handle #include *)
(* Anything else? *)

(* Edsger Lexical Analyser 
   Heavily inspired by: 
   https://courses.softlab.ntua.gr/compilers/2011a/examples/minibasic/OCaml/lexer/Lexer.mll *)

(* Header Section *)

{
    type token = 
         T_eof  | T_id | T_constint | T_constreal
        
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

        | T_assign | T_eq | T_neq | T_gt | T_lt 
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

let digit = ['0'-'9']
let letter = ['a'-'z''A'-'Z']
let whitespace = [' ''\n''\t']

let exp_part = digit+ (['e''E'] (['+''-']?) digit+)? 

let id_trail = letter | digit | '_'

(* Comments Regex *)
let one_liner = "//" [^'\n']* '\n'
let multiliner = "/*" _* "*/" (* Is this enough? (* It is if we have a lazy evaluator *) *)
(* https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch07s06.html *)


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

    | letter (id_trail)+         { T_id }        (* Identifiers *)
    | digit+                     { T_constint }  (* Unsigned integer constants *)
    | digit+ '.' exp_part?       { T_constreal } (* Unsigned real constants *)


    | (one_liner | multiliner)   { lexer lexbuf } (* Ignore all comments *)
    | whitespace+                { lexer lexbuf } (* Ignore all whitespaces *)

    |  eof          { T_eof }
    |  _ as chr     { Printf.eprintf "Invalid character: '%c' (ascii: %d)" chr (Char.code chr);
                      lexer lexbuf }

(* Trailer Section *)
{
    let string_of_token token =
    match token with
          T_eof             -> "T_eof"
        | T_id              -> "T_id"
        | T_constint        -> "T_constint"
        | T_constreal       -> "T_constreal"

        (* More to insert here *)

        | T_bool            -> "T_bool"
        | T_break           -> "T_break"
        | T_byref           -> "T_byref"
        | T_char            -> "T_char"
        | T_continue        -> "T_continue"
        | T_delete          -> "T_delete"
        | T_double          -> "T_double"
        | T_else            -> "T_else"
        | T_for             -> "T_for"
        | T_false           -> "T_false"
        | T_if              -> "T_if"
        | T_int             -> "T_int"
        | T_new             -> "T_new" 
        | T_NULL            -> "T_NULL"
        | T_return          -> "T_return"
        | T_true            -> "T_true"
        | T_void            -> "T_void"
        | T_assign          -> "T_assign"
        | T_eq              -> "T_eq"
        | T_neq             -> "T_neq"
        | T_gt              -> "T_gt"
        | T_lt              -> "T_lt"
        | T_ge              -> "T_ge"
        | T_le              -> "T_le"
        | T_plus            -> "T_plus"
        | T_minus           -> "T_minus"
        | T_times           -> "T_times"
        | T_div             -> "T_div"  
        | T_mod             -> "T_mod"
        | T_ref             -> "T_ref"
        | T_not             -> "T_not"
        | T_and             -> "T_and"
        | T_or              -> "T_or"
        | T_question        -> "T_question"
        | T_colon           -> "T_colon"
        | T_comma           -> "T_comma"
        | T_plusplus        -> "T_plusplus"
        | T_minusminus      -> "T_minusminus"
        | T_plusequals      -> "T_plusequals"
        | T_minusequals     -> "T_minusequals"
        | T_timesequals     -> "T_timesequals"
        | T_divequals       -> "T_divequals"
        | T_modequals       -> "T_modequals"

        | T_semicolon       -> "T_semicolon"
        | T_leftpar         -> "T_leftpar"
        | T_rightpar        -> "T_rightpar"
        | T_leftsqbr        -> "T_leftsqbr"
        | T_rightsqbr       -> "T_rightsqbr"
        | T_leftbr          -> "T_leftbr"
        | T_rightbr         -> "T_rightbr"

  let main =
    let lexbuf = Lexing.from_channel stdin in
    let rec loop () =
      let token = lexer lexbuf in
      Printf.printf "token=%s, lexeme=\"%s\"\n"
        (string_of_token token) (Lexing.lexeme lexbuf);
      if token <> T_eof then loop () in
    loop ()
}
