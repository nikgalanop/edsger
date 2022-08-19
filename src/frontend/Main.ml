let main =
  if (Array.length Sys.argv <> 2) then 
    Printf.eprintf "\027[93mUsage:\027[0m ./edsger <filename>.eds\n"
  else begin
    let fn = Sys.argv.(1) in
    if (not @@ Sys.file_exists fn) then begin
      let msg = Printf.sprintf "File '%s' does not exist" fn in
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
      exit 1
    end;
    let ext = Filename.extension fn in
    if (ext <> ".eds") then begin
      let msg = Printf.sprintf "Cannot compile a file with extension %s" ext in
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
      exit 1
    end;
    let lb = Lexer.add_file fn in 
    begin try
      let t = Parser.program Lexer.lexer lb in Ast.print_ast t;
      Semantic.sem_analysis t;
      Printf.eprintf "• Compiled Succesfully: \027[92m✓\027[0m\n";
      exit 0
    with 
    | Lexer.LexFailure (pos, msg) | Semantic.SemFailure (pos, msg) -> 
      Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
    | Failure msg -> 
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
    | _ -> let pos = lb.Lexing.lex_curr_p in
      Utilities.print_diagnostic ~p:(Some pos) "Syntax Error" Utilities.Error;
    end;
    Printf.eprintf "• Compiled Successfully: \027[1;31m✗\027[0m\n";
  end; 
  exit 1;