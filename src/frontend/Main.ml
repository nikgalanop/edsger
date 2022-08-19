let usage_msg = "\027[93mUsage:\027[0m ./edsger [options] <file>.eds (The latest file provided will be used)\n\027[93mOptions:\027[0m"
let fn = ref ""
let opt_flag = ref false 
let asm_flag = ref false
let ir_flag = ref false

let anon_fun filename = 
  fn := filename

let speclist = 
  [("-O", Arg.Set opt_flag, "Enables code optimization");
   ("-f", Arg.Set asm_flag, "Accepts an Edsger program via stdin and dumps the final code in stdout");
   ("-i", Arg.Set ir_flag, "Accepts an Edsger program via stdin and dumps the LLVM IR in stdout")
  ]

let () =
  Arg.parse speclist anon_fun usage_msg;
  let from_file = not (!asm_flag || !ir_flag) in
  if (from_file) then begin
    if (not @@ Sys.file_exists !fn) then begin
      let msg = Printf.sprintf "File '%s' does not exist" !fn in
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
      exit 1
    end;
    let ext = Filename.extension !fn in
    if (ext <> ".eds") then begin
      let msg = Printf.sprintf "Cannot compile a file with extension '%s'" ext in
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
      exit 1
    end
  end;
  let lb = if (from_file) then Lexer.add_file !fn 
    else Lexer.add_stdin () 
  in begin try
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
  exit 0;