let main =
  if (Array.length Sys.argv <> 2) then (Printf.eprintf "Usage: ./edsger <filename>.eds\n")
  else 
  (
    let fn = Sys.argv.(1) in
      if (not @@ Sys.file_exists fn) then 
        (
          let msg = Printf.sprintf "File '%s' does not exist" fn in
          Utilities.print_diagnostic ~p:None msg Utilities.Error;
          exit 1
        );
    let c = Stdlib.open_in fn in
    let lb = Lexing.from_channel c in 
      Lexing.set_filename lb fn;
    try
        let _ = Parser.program Lexer.lexer lb in (); exit 0
    with _ -> 
        let pos = lb.Lexing.lex_curr_p in
        Utilities.print_diagnostic ~p:(Some pos) "Syntax Error" Utilities.Error;
  );   
  exit 1;