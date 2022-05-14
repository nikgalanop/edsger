let main =
  Lexer.init; 
  try
    Parser.program Lexer.lexer (Lexer.current_buffer);
    Printf.eprintf "Okay I think\n";
    exit 0
  with _ ->
    let pos = (Lexer.current_buffer).Lexing.lex_curr_p 
    in Printf.eprintf "(File '%s' - Line %d) Syntax Error\n" 
                        pos.pos_fname pos.pos_lnum ;
    exit 1