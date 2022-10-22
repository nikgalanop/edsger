(* Header Section *)

{
  open Parser
  module StringSet = Set.Make(String)
  type globalSet = StringSet.t ref
  let set : globalSet = ref StringSet.empty
  let cdStack = Stack.create ()

  let add_file filename = 
    set := StringSet.add filename !set;
    let dir = Filename.dirname filename in
    Stack.push dir cdStack;
    let lb = if (filename <> "stdin") then
      Stdlib.open_in filename |> 
      Lexing.from_channel
    else
      Lexing.from_channel stdin 
    in Lexing.set_filename lb filename;
    lb

  let get_cd () = 
    Stack.top cdStack

  let cd_pop () = 
    ignore @@ Stack.pop_opt cdStack

  let safe_find filename (set:globalSet) = 
    try Some (StringSet.find filename !set) with
    | Not_found -> None 

  exception LexFailure of Lexing.position * string 

  let lex_fail pos msg = 
    raise (LexFailure (pos, msg))
}

(* Definitions Section *)

let digit = ['0'-'9']
let hex_digit = digit | ['a'-'f']
let letter = ['a'-'z''A'-'Z']
let whitespace = [' ''\t''\r']

(* Identifiers Regexes *)
let id_trail = (letter | digit | '_')*
let identifier = letter id_trail

(* Numerical Values Regexes *)
let integer = digit+
let exp_part = integer (['e''E'] (['+''-']?) integer)? 
let double = integer '.' exp_part? 

(* Characters Regexes *)
let common_char = [^'\"''\'''\\'] 
let hex_code = hex_digit hex_digit
let esc_char = '\\' (['n''t''r''0''\\''\'''\"'] | ('x' hex_code))
let char = '\'' ((common_char | esc_char) as c) '\''

(* String Regexes *)
let str_body = ([^'\n''\"'] | '\\''\"')*
let string = '\"' (str_body as s) '\"'  

(* Comments Regexes *)
let one_liner = "//" [^'\n']* '\n'

(* Directives Regexes *)
let name = '\"' (([^'"'' ''\t''\n'])+ as filename) '\"' 
let incl = "#include" whitespace* name

(* Rules Section *)
rule lexer = parse 

  (* Directives *)
  | incl    { let pos = lexbuf.Lexing.lex_start_p in
              let line_pos = pos.pos_cnum - pos.pos_bol in
              if (line_pos <> 0) then
                lex_fail pos "Directives should be in the beginning of a line";
              let fn = ref filename in
              let cd = get_cd () in 
              let cfn = if cd <> "." then Printf.sprintf "%s/%s" cd filename
                else filename in 
              if (not @@ Sys.file_exists cfn) then begin
                fn := Utilities.default_lib_header !fn;
                if (not @@ Sys.file_exists !fn) then begin
                  let msg = Printf.sprintf "Cannot include non-existing file '%s'" filename in
                  lex_fail pos msg
                end
              end 
              else fn := cfn; 
              let ext = Filename.extension !fn in
              if (ext <> ".eds" && ext <> ".h") then begin
                let msg = Printf.sprintf "Can only include files with extension \
                  '.h' or '.eds', not '%s'" ext in
                lex_fail pos msg
              end;
              let res = safe_find !fn set in
              match res with
              | None -> let lb = add_file !fn in 
                begin try  
                  let t = Parser.program lexer lb in
                  cd_pop ();
                  T_include t
                with | Parser.Error -> let pos = lb.Lexing.lex_start_p in
                  Utilities.print_diagnostic ~p:(Some pos) "Syntax Error" Utilities.Error; 
                  exit 1 
                end
              | _   -> let msg = Printf.sprintf "Tried to include '%s' twice" !fn in
                Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Warning;
                T_include [] } 

  (* Keywords *)
  | "bool"      { T_bool }
  | "break"     { T_break }
  | "byref"     { T_byref }
  | "char"      { T_char }
  | "continue"  { T_continue }
  | "delete"    { T_delete }
  | "double"    { T_double }
  | "else"      { T_else }
  | "for"       { T_for }
  | "false"     { T_false }
  | "if"        { T_if }
  | "int"       { T_int }
  | "new"       { T_new }
  | "NULL"      { T_NULL }
  | "return"    { T_return }
  | "true"      { T_true }
  | "void"      { T_void }

  (* Symbolic Operators *)
  | '='         { T_assign }
  | "=="        { T_eq }
  | "!="        { T_neq }
  | ">"         { T_gt }
  | "<"         { T_lt }
  | ">="        { T_ge }
  | "<="        { T_le }
  | "+"         { T_plus }
  | "-"         { T_minus }
  | "*"         { T_times }
  | "/"         { T_div }
  | "%"         { T_mod }
  | "&"         { T_ref }
  | "!"         { T_not }
  | "&&"        { T_and }
  | "||"        { T_or }
  | "?"         { T_question }
  | ":"         { T_colon }
  | ","         { T_comma }
  | "++"        { T_plusplus }
  | "--"        { T_minusminus }
  | "+="        { T_plusequals }
  | "-="        { T_minusequals }
  | "*="        { T_timesequals }
  | "/="        { T_divequals }
  | "%="        { T_modequals }

  (* Seperators *)
  | ";"         { T_semicolon }
  | "("         { T_leftpar }
  | ")"         { T_rightpar }
  | "["         { T_leftsqbr }
  | "]"         { T_rightsqbr }
  | "{"         { T_leftbr }
  | "}"         { T_rightbr }

  (* Rest *)
  | identifier  { T_id (Lexing.lexeme lexbuf)}        
  | integer     { try
                    let num = int_of_string @@ Lexing.lexeme lexbuf in 
                    if (num > 0x7fff) then raise Exit else
                    T_constint num 
                  with | _ -> let pos = lexbuf.Lexing.lex_start_p in
                  lex_fail pos "Provided a big integer constant" } 
  | double      { try  
                    let num = float_of_string @@ Lexing.lexeme lexbuf in 
                    T_constreal num 
                  with | _ -> let pos = lexbuf.Lexing.lex_start_p in
                  lex_fail pos "Provided an invalid double representation" } 
  | char        { match c with 
                  | "\\0" -> T_constchar (Char.chr 0)
                  | _ -> try 
                      let un = Scanf.unescaped c in 
                      T_constchar (un).[0]
                    with | _ -> let pos = lexbuf.Lexing.lex_start_p in
                    lex_fail pos "Provided an improperly escaped character" } 
  | string      { try  
                    let r = Str.regexp {|\\0|} in
                    let templ = String.make 1 (Char.chr 0) in
                    let str = s |> 
                    Str.global_replace r templ |>
                    Scanf.unescaped in
                    T_string str 
                  with | _ -> let pos = lexbuf.Lexing.lex_start_p in
                  lex_fail pos "Provided an improperly escaped string" } 
  | one_liner   { Lexing.new_line lexbuf; lexer lexbuf } 
  | "/*"        { multi_comment lexbuf }
  | '\n'        { Lexing.new_line lexbuf; lexer lexbuf }
  | whitespace+ { lexer lexbuf }
  |  eof        { T_eof }
  |  _ as chr   { let pos = lexbuf.Lexing.lex_curr_p in  
                  let msg = Printf.sprintf "Invalid Character '%c' (ASCII Code: %d)" 
                    chr (Char.code chr) in
                  Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
                  lexer lexbuf }
                  
(* Count the lines of the multilined comments *)
and multi_comment = parse 
    "*/"          { lexer lexbuf }
  | '\n'          { Lexing.new_line lexbuf; multi_comment lexbuf }
  | '*'           { multi_comment lexbuf } 
  | [^'*''\n']    { multi_comment lexbuf }

(* Trailer Section *)

{}