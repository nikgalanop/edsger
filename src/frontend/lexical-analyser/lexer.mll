(* Header Section *)

{
 open Parser
    module StringSet = Set.Make(String)
    type globalSet = StringSet.t ref
    let set : globalSet = ref StringSet.empty

    let add_file filename = 
        set := StringSet.add filename !set;
        let c = Stdlib.open_in filename in
        let lb = Lexing.from_channel c in
        Lexing.set_filename lb filename;
        lb

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

(* Directives Regex *)
let name = '\"' (([^'"'' ''\t''\n'])+ as filename) '\"' 
let incl = "#include" whitespace* name

(* Rules Section *)

rule lexer = parse 

    (* Directives *)

      incl    {      
                      let pos = lexbuf.Lexing.lex_start_p in
                      let line_pos = pos.pos_cnum - pos.pos_bol in
                      if (line_pos <> 0) then begin
                        Utilities.print_diagnostic ~p:(Some pos) 
                            "Directives should be in the beginning of a line" Utilities.Error;
                        exit 1 end
                      else
                        if (not @@ Sys.file_exists filename) then 
                          let msg = Printf.sprintf "Cannot include non-existing file '%s'" filename in
                          Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
                          exit 1
                        else
                          let res = safe_find filename set in
                          match res with
                          | None -> let lb = add_file filename in 
                              let t = Parser.program lexer lb in
                              T_include t
                          | _   -> let msg = Printf.sprintf "Tried to include '%s' twice" filename
                              in Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Warning;
                              T_include []
              } 

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

    | '='           { T_assign }
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

    | letter (id_trail)*                        { T_id (Lexing.lexeme lexbuf)}        (* Identifiers *)
    | digit+                                    { T_constint (int_of_string @@ Lexing.lexeme lexbuf)}  (* Unsigned integer constants *)
    | digit+ '.' exp_part?                      { T_constreal (float_of_string @@ Lexing.lexeme lexbuf)} (* Unsigned real constants *)

    | '\'' (common_char | esc_char as c) '\''       {  
                                                       match c with 
                                                       | "\\0" -> T_constchar (Char.chr 0)
                                                       | _ -> T_constchar (Scanf.unescaped c).[0] 
                                                    } 
    | '\"' ([^'\n''\"'] | '\\''\"')* '\"'       { T_string (Lexing.lexeme lexbuf)} 
    (* Use whatever you want besides new line or a double quote or you must use the escaping character for double quotes *)                                                         

    | one_liner                                 { Lexing.new_line lexbuf; lexer lexbuf } (* Ignore one-liner comments *)
    | "/*"                                      { multi_comment lexbuf }  (* Ignore multi-line comments *)
    | '\n'                                      { Lexing.new_line lexbuf; lexer lexbuf } (* New Line *)
    | whitespace+                               { lexer lexbuf } (* Ignore all whitespaces *)

    |  eof                                      { T_eof }
    
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