(* 
  Edsger Lexical Analyser 
  Heavily inspired by: 
  https://courses.softlab.ntua.gr/compilers/2011a/examples/minibasic/OCaml/lexer/Lexer.mll 
*)

(* Header Section *)

{
    open Parser

    let s :(Lexing.lexbuf Stack.t) = Stack.create()

    module StringSet = Set.Make(String)
    type globalset = {mutable s: StringSet.t}
    let set: globalset = {s = StringSet.empty}
    
    let safe_find filename (set:globalset) = 
      try Some (StringSet.find filename set.s) with
          | Not_found -> None 

    let init = 
        Stack.push (Lexing.from_channel stdin) s

    let push_buffer buffer =
        Stack.push buffer s
    
    let current_buffer = 
        Stack.top s

    (* type token = 
          T_eof | T_id | T_constint | T_constreal
        | T_constchar | T_string  

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
        | T_rightsqbr | T_leftbr | T_rightbr *)
}

(* Definitions Section *)

let digit = ['0'-'9']
let hex_digit = digit | ['a'-'f']
let letter = ['a'-'z''A'-'Z']
let whitespace = [' ''\t''\r']

let id_trail = letter | digit | '_'

let exp_part = digit+ (['e''E'] (['+''-']?) digit+)? 

(* Characters Regex *)
let common_char = [^'\"''\'''\\'] 
let hex_code = hex_digit hex_digit
let esc_char = '\\' (['n''t''r''0''\\''\'''\"'] | ('x' hex_code))

(* Comments Regex *)
let one_liner = "//" [^'\n']* '\n'
(*  https://stackoverflow.com/a/32320759 *)

(* Directives Regex *)

(* Have not taken care of the "starting at the beginning of line" requirement *)
let name = '\"' (([^'"' '\n'])+ as filename) '\"'
let incl = "#include" whitespace* name 

(* Rules Section *)

rule lexer = parse 

    (* Directives *)

      incl          { 
                      let res = safe_find filename set in
                      (
                        match res with
                          | None    ->  ( 
                                          set.s <- StringSet.add filename set.s;
                                          let c = open_in filename in
                                            Stack.push (Lexing.from_channel c) s;
                                          Lexing.set_filename (Stack.top s) filename;
                                        )
                          | _       -> ()
                      );
                        lexer (Stack.top s)
                    } (* In case we face a cyclical inclusion or many files including one file,
                         we ignore the latest problematic inclusion *)

    (* Keywords *)

    | "bool"        { T_bool }
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

    | letter (id_trail)*                        { T_id }        (* Identifiers *)
    | digit+                                    { T_constint }  (* Unsigned integer constants *)
    | digit+ '.' exp_part?                      { T_constreal } (* Unsigned real constants *)

    | '\'' (common_char | esc_char ) '\''       { T_constchar }
    | '\"' ([^'\n''\"'] | '\\''\"')* '\"'       { T_string } (* Simple incomplete implementation *)
    (* Use whatever you want besides new line or a double quote or you must use the escaping character for double quotes *)                                                         

    | one_liner                                 { Lexing.new_line (Stack.top s); lexer (Stack.top s) } (* Ignore one-liner comments *)
    | "/*"                                      { multi_comment (Stack.top s) }  (* Ignore multi-line comments *)
    | '\n'                                      { Lexing.new_line (Stack.top s); lexer (Stack.top s) } (* New Line *)
    | whitespace+                               { lexer (Stack.top s) } (* Ignore all whitespaces *)

    |  eof                                      { 
                                                  let t = Stack.pop s;
                                                  in
                                                    if (not (Stack.is_empty s) ) 
                                                    then ( lexer (Stack.top s) )
                                                    else ( Stack.push t s; T_eof ) 
                                                }
    
    |  _ as chr                                 { 
                                                  let pos = (Stack.top s).Lexing.lex_curr_p 
                                                  in Printf.eprintf "(File '%s' - Line %d) Invalid character: '%c' (ASCII Code: %d)\n" 
                                                      pos.pos_fname pos.pos_lnum chr (Char.code chr);
                                                  lexer (Stack.top s) 
                                                }

(* Count the lines of the multilined comments *)
and multi_comment = parse 
    "*/"          { lexer (Stack.top s) }
  | '\n'          { Lexing.new_line (Stack.top s); multi_comment (Stack.top s) }
  | '*'           { multi_comment (Stack.top s) } (* Ignored *)
  | [^'*''\n']    { multi_comment (Stack.top s) } (* Ignored. Handled above. *)



(* Trailer Section *)
{
    (* let string_of_token token =
    match token with
          T_eof             -> "T_eof"
        | T_id              -> "T_id"
        | T_constint        -> "T_constint"
        | T_constreal       -> "T_constreal"
        | T_constchar       -> "T_constchar"
        | T_string          -> "T_string"

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
    Stack.push (Lexing.from_channel stdin) s;
    let rec loop () =
      let token = lexer (Stack.top s) in
      Printf.printf "token=%s, lexeme=\"%s\"\n"
          (string_of_token token) (Lexing.lexeme (Stack.top s));
      if token <> T_eof then loop () in
    loop () *)
}
