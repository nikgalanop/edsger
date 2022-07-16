(* 
  Edsger Lexical Analyser 
  Heavily inspired by: 
  https://courses.softlab.ntua.gr/compilers/2011a/examples/minibasic/OCaml/lexer/Lexer.mll 
*)

(* Header Section *)

{
 open Parser
    module StringSet = Set.Make(String)
    type globalSet = StringSet.t ref
    let set : globalSet = ref StringSet.empty

    let safe_find filename (set:globalSet) = 
      try Some (StringSet.find filename !set) with
          | Not_found -> None 
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

let name = '\"' (([^'"'' ''\t''\n'])+ as filename) '\"' 
let incl = "#include" whitespace* name

(* Rules Section *)

rule lexer = parse 

    (* Directives *)

      incl    {      
                      let pos = lexbuf.Lexing.lex_start_p in
                        (*  
                            " The difference between pos_cnum and pos_bol 
                            is the character offset within the line (i.e.
                            the column number, assuming each character is
                            one column wide)." 
                            (Source: https://ocaml.org/api/Lexing.html)
                        *)
                        let line_pos = pos.pos_cnum - pos.pos_bol in (* Position of incl munch's first character in line *)
                        if (line_pos <> 0) then  
                        ( 
                          Utilities.print_diagnostic ~p:(Some pos) "Directives should be in the beginning of a line" Utilities.Error;
                          exit 1
                        ) 
                        else
                        (
                          if (not @@ Sys.file_exists filename) then 
                          (
                            let msg = Printf.sprintf "Cannot include non-existing file '%s'" filename in
                            Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
                            exit 1
                          )
                          else 
                          (
                            let res = safe_find filename set in
                            (
                              match res with
                                  | None    ->  
                                  ( 
                                    set := StringSet.add filename !set;
                                    let c = Stdlib.open_in filename in
                                    ( 
                                      let lb = Lexing.from_channel c in
                                      Lexing.set_filename lb filename;
                                      let _ = Parser.program lexer lb in (* Use this when AST is implemented *)
                                      ()
                                    )
                                  )
                              | _       -> ( 
                                              let msg = Printf.sprintf "Tried to include '%s' twice" filename
                                              in Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Warning;
                                            )
                            );
                            Printf.printf "INCL\n";
                            T_include
                          )
                       )
              } (* In case we face a cyclical inclusion or many files including one file,
                   we ignore the latest problematic inclusion *)

    (* Keywords *)

    | "bool"        { Printf.printf "BOOL: %s\n" @@ Lexing.lexeme lexbuf; T_bool }
    | "break"       { Printf.printf "BREAK: %s\n" @@ Lexing.lexeme lexbuf; T_break }
    | "byref"       { Printf.printf "BYREF: %s\n" @@ Lexing.lexeme lexbuf; T_byref }
    | "char"        { Printf.printf "CHAR: %s\n" @@ Lexing.lexeme lexbuf; T_char }
    | "continue"    { Printf.printf "CONTINUE: %s\n" @@ Lexing.lexeme lexbuf; T_continue }
    | "delete"      { Printf.printf "DEL: %s\n" @@ Lexing.lexeme lexbuf; T_delete }
    | "double"      { Printf.printf "DOUBLE_T: %s\n" @@ Lexing.lexeme lexbuf; T_double }
    | "else"        { Printf.printf "ELSE: %s\n" @@ Lexing.lexeme lexbuf; T_else }
    | "for"         { Printf.printf "FOR: %s\n" @@ Lexing.lexeme lexbuf; T_for }
    | "false"       { Printf.printf "FALSE: %s\n" @@ Lexing.lexeme lexbuf; T_false }
    | "if"          { Printf.printf "IF: %s\n" @@ Lexing.lexeme lexbuf; T_if }
    | "int"         { Printf.printf "INT_T: %s\n" @@ Lexing.lexeme lexbuf; T_int }
    | "new"         { Printf.printf "NEW: %s\n" @@ Lexing.lexeme lexbuf; T_new }
    | "NULL"        { Printf.printf "NULL: %s\n" @@ Lexing.lexeme lexbuf; T_NULL }
    | "return"      { Printf.printf "RETURN: %s\n" @@ Lexing.lexeme lexbuf; T_return }
    | "true"        { Printf.printf "TRUE: %s\n" @@ Lexing.lexeme lexbuf; T_true }
    | "void"        { Printf.printf "VOID: %s\n" @@ Lexing.lexeme lexbuf; T_void }

    (* Symbolic Operators *)

    | '='           { Printf.printf "ASSIGN:%s\n" @@ Lexing.lexeme lexbuf; T_assign }
    | "=="          { Printf.printf "EQ:%s\n" @@ Lexing.lexeme lexbuf; T_eq }
    | "!="          { Printf.printf "NONEQ:%s\n" @@ Lexing.lexeme lexbuf; T_neq }
    | ">"           { Printf.printf "GT:%s\n" @@ Lexing.lexeme lexbuf; T_gt }
    | "<"           { Printf.printf "LT:%s\n" @@ Lexing.lexeme lexbuf; T_lt }
    | ">="          { Printf.printf "GE:%s\n" @@ Lexing.lexeme lexbuf; T_ge }
    | "<="          { Printf.printf "LE:%s\n" @@ Lexing.lexeme lexbuf; T_le }
    | "+"           { Printf.printf "PLUS:%s\n" @@ Lexing.lexeme lexbuf; T_plus }
    | "-"           { Printf.printf "MINUS:%s\n" @@ Lexing.lexeme lexbuf; T_minus }
    | "*"           { Printf.printf "TIMES:%s\n" @@ Lexing.lexeme lexbuf; T_times }
    | "/"           { Printf.printf "DIV:%s\n" @@ Lexing.lexeme lexbuf; T_div }
    | "%"           { Printf.printf "MOD:%s\n" @@ Lexing.lexeme lexbuf; T_mod }
    | "&"           { Printf.printf "REF:%s\n" @@ Lexing.lexeme lexbuf; T_ref }
    | "!"           { Printf.printf "NOT:%s\n" @@ Lexing.lexeme lexbuf; T_not }
    | "&&"          { Printf.printf "AND:%s\n" @@ Lexing.lexeme lexbuf; T_and }
    | "||"          { Printf.printf "OR:%s\n" @@ Lexing.lexeme lexbuf; T_or }
    | "?"           { Printf.printf "QUEST:%s\n" @@ Lexing.lexeme lexbuf; T_question }
    | ":"           { Printf.printf "COLON:%s\n" @@ Lexing.lexeme lexbuf; T_colon }
    | ","           { Printf.printf "COMMA:%s\n" @@ Lexing.lexeme lexbuf; T_comma }
    | "++"          { Printf.printf "PLUPLU:%s\n" @@ Lexing.lexeme lexbuf; T_plusplus }
    | "--"          { Printf.printf "MINMIN:%s\n" @@ Lexing.lexeme lexbuf; T_minusminus }
    | "+="          { Printf.printf "PLUSEQ:%s\n" @@ Lexing.lexeme lexbuf; T_plusequals }
    | "-="          { Printf.printf "MINEQ:%s\n" @@ Lexing.lexeme lexbuf; T_minusequals }
    | "*="          { Printf.printf "TIMEQ:%s\n" @@ Lexing.lexeme lexbuf; T_timesequals }
    | "/="          { Printf.printf "DIVEQ:%s\n" @@ Lexing.lexeme lexbuf; T_divequals }
    | "%="          { Printf.printf "MODEQ:%s\n" @@ Lexing.lexeme lexbuf; T_modequals }
    
    (* Seperators *)

    | ";"           { Printf.printf "SEMIC:%s\n" @@ Lexing.lexeme lexbuf; T_semicolon }
    | "("           { Printf.printf "LPAR: %s\n" @@ Lexing.lexeme lexbuf; T_leftpar }
    | ")"           { Printf.printf "RPAR:%s\n" @@ Lexing.lexeme lexbuf; T_rightpar }
    | "["           { Printf.printf "LSPAR:%s\n" @@ Lexing.lexeme lexbuf; T_leftsqbr }
    | "]"           { Printf.printf "RSPAR:%s\n" @@ Lexing.lexeme lexbuf; T_rightsqbr }
    | "{"           { Printf.printf "LBRA:%s\n" @@ Lexing.lexeme lexbuf; T_leftbr }
    | "}"           { Printf.printf "RBRA:%s\n" @@ Lexing.lexeme lexbuf; T_rightbr }

    (* Rest *)

    | letter (id_trail)*                        { Printf.printf "ID: %s\n" @@ Lexing.lexeme lexbuf; T_id }        (* Identifiers *)
    | digit+                                    { Printf.printf "INT: %s\n" @@ Lexing.lexeme lexbuf; T_constint }  (* Unsigned integer constants *)
    | digit+ '.' exp_part?                      { Printf.printf "REAL: %s\n" @@ Lexing.lexeme lexbuf; T_constreal } (* Unsigned real constants *)

    | '\'' (common_char | esc_char ) '\''       { Printf.printf "CHAR: %s\n" @@ Lexing.lexeme lexbuf; T_constchar }
    | '\"' ([^'\n''\"'] | '\\''\"')* '\"'       { Printf.printf "STR: %s\n" @@ Lexing.lexeme lexbuf; T_string } (* Simple incomplete implementation *)
    (* Use whatever you want besides new line or a double quote or you must use the escaping character for double quotes *)                                                         

    | one_liner                                 { Lexing.new_line lexbuf; lexer lexbuf } (* Ignore one-liner comments *)
    | "/*"                                      { multi_comment lexbuf }  (* Ignore multi-line comments *)
    | '\n'                                      { Lexing.new_line lexbuf; lexer lexbuf } (* New Line *)
    | whitespace+                               { lexer lexbuf } (* Ignore all whitespaces *)

    |  eof                                      { let pos = lexbuf.Lexing.lex_curr_p in  
                                                  Printf.printf "EOF (File: %s)\n" pos.pos_fname; 
                                                  T_eof
                                                }
    
    |  _ as chr                                 { 
                                                  let pos = lexbuf.Lexing.lex_curr_p in  
                                                  let msg = Printf.sprintf "Invalid Character '%c' (ASCII Code: %d)" 
                                                             chr (Char.code chr)
                                                  in
                                                  Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
                                                  lexer lexbuf 
                                                }

(* Count the lines of the multilined comments *)
and multi_comment = parse 
    "*/"          { lexer lexbuf }
  | '\n'          { Lexing.new_line lexbuf; multi_comment lexbuf }
  | '*'           { multi_comment lexbuf } (* Ignored *)
  | [^'*''\n']    { multi_comment lexbuf } (* Ignored. Handled above. *)

(* Trailer Section *)
{}