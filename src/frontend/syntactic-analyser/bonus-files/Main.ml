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
    (* try *)
        let t = Parser.program Lexer.lexer lb in Ast.print_ast t;
        Semantic.sem_analysis t;
        exit 0
    (* with 
    | Failure msg -> Utilities.print_diagnostic ~p:None (msg) Utilities.Error;
    (* | Parser.MenhirBasics.Error -> let pos = lb.Lexing.lex_curr_p in
        Utilities.print_diagnostic ~p:(Some pos) "Syntax Error" Utilities.Error;  *)
    | e -> Utilities.print_diagnostic ~p:None (Printexc.to_string e) Utilities.Error; *)
  );   
  exit 1;