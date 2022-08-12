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
    let lb = Lexer.add_file fn in 
    let print_failure () = 
      Printf.eprintf "\027[1;31m✗\027[0m\n";
      Printf.eprintf "• Compiled Successfully: \027[1;31m✗\027[0m\n";
    in
    try
      Printf.eprintf "\n";
      Printf.eprintf "• Lexical & Syntactic Analysis: ";
      let t = Parser.program Lexer.lexer lb in Ast.print_ast t;
      Printf.eprintf "\027[92m✓\027[0m\n";
      Printf.eprintf "• Semantic Analysis: ";  
      Semantic.sem_analysis t;
      Printf.eprintf "\027[92m✓\027[0m\n";
      Printf.eprintf "• Compiled Succesfully: \027[92m✓\027[0m\n";
      exit 0
    with 
    | Lexer.LexFailure (pos, msg) | Semantic.SemFailure (pos, msg) -> 
        print_failure ();
        Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
    | Failure msg -> print_failure ();
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
    | _ -> let pos = lb.Lexing.lex_curr_p in
        print_failure ();
        Utilities.print_diagnostic ~p:(Some pos) "Syntax Error" Utilities.Error;
  );   
  exit 1;