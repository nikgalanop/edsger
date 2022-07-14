let main =
  if (Array.length Sys.argv <> 2) then (Printf.eprintf "Usage: ./edsger <filename>.eds\n")
  else 
  (
    let fn = Sys.argv.(1) in
      if (not @@ Sys.file_exists fn) then (Printf.eprintf "File: '%s' does not exist\n" fn; exit 1);
    let c = Stdlib.open_in fn in
    let lb = Lexing.from_channel c in 
      Lexing.set_filename lb fn;
    try
        Parser.program Lexer.lexer lb; exit 0
    with _ -> 
        let pos = lb.Lexing.lex_curr_p in
        let line_pos = (pos.pos_cnum - pos.pos_bol + 1) in
        Printf.eprintf "(File: '%s' - Line %d, Column %d) Syntax Error\n" 
                            pos.pos_fname pos.pos_lnum line_pos
  );   
  exit 1;