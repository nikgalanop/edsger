let usage_msg = "\027[93mUsage:\027[0m ./edsger [options] <file>.eds \n\027[93mOptions:\027[0m"
let fn = ref ""
let opt_flag = ref false 
let asm_flag = ref false
let ir_flag = ref false
let counter = ref 0

let anon_fun filename = 
  counter := !counter + 1;
  fn := filename

let speclist = 
  [("-O", Arg.Set opt_flag, "Enables LLVM IR optimization");
   ("-f", Arg.Set asm_flag, "Accepts an Edsger program via stdin and dumps the assembly in stdout");
   ("-i", Arg.Set ir_flag, "Accepts an Edsger program via stdin and dumps the LLVM IR in stdout")]

let cli_error msg = 
  Utilities.print_diagnostic ~p:None msg Utilities.Error;
  exit 1

let execute_cmd cmd msg = 
  if (Sys.command cmd <> 0) then begin
    prerr_newline (); failwith msg
  end

let () =
  Arg.parse speclist anon_fun usage_msg;
  if (!asm_flag && !ir_flag) then begin
    let msg = "Cannot print both the assembly and the LLVM IR at the same time" in
    cli_error msg;
  end;
  let from_file = not (!asm_flag || !ir_flag) in
  if (from_file) then begin
    if (!counter > 1) then begin 
      let msg = "Provided more than one files to compile. See: ./edsger -help" in 
      cli_error msg
    end;
    if (not @@ Sys.file_exists !fn) then begin
      let msg = Printf.sprintf "File '%s' does not exist" !fn in
      cli_error msg
    end;
    let ext = Filename.extension !fn in
    if (ext <> ".eds") then begin
      let msg = Printf.sprintf "Cannot compile a file with extension '%s'" ext in
      cli_error msg
    end;
  end
  else if (!fn <> "") then begin
      let msg = "Provided a file to read from, even though it is expected to read from stdin. \
        See: ./edsger -help" in 
      cli_error msg 
  end;
  let lb = Lexer.add_file @@ 
    if (from_file) then !fn else "stdin" 
  in begin try
    let t = Parser.program Lexer.lexer lb in 
    (* Ast.print_ast t; *)
    Semantic.sem_analysis t;
    let lmodule = Codegen.codegen t in
    if (!opt_flag) then Optimizer.optimize lmodule;
    if (from_file) then begin
      let n = Filename.remove_extension !fn in 
      let irfn = Printf.sprintf "%s.ll" n in 
      let f = Out_channel.open_text irfn in 
      Out_channel.output_string f (Llvm.string_of_llmodule lmodule);
      Out_channel.close f;
      let cmd = Printf.sprintf "llc-15 -march=\"x86-64\" %s" irfn in 
      execute_cmd cmd "LLC produced an error during the compilation phase. \
        Check above for more details";
      let clang_flags = "-lm -o" in
      let cmd = Printf.sprintf "clang %s %s.out %s.s edsgerlib.a " 
        clang_flags n n in 
      execute_cmd cmd "Clang produced an error during the linking phase. \
        Check above for more details";
      Printf.eprintf "• Compiled Succesfully: \027[92m✓\027[0m\n"
    end
    else if (!ir_flag) then 
      print_string @@ Llvm.string_of_llmodule lmodule
    else begin 
      let nm, f = Filename.open_temp_file ~perms:438 "__temp__" ".ll" in 
      Out_channel.output_string f (Llvm.string_of_llmodule lmodule);
      Out_channel.close f;
      let n = Filename.remove_extension nm in 
      let cmd = Printf.sprintf "llc-15 -march=\"x86-64\" < %s" nm in 
      execute_cmd cmd "LLC produced an error during the compilation phase. \
        Check above for more details"
    end;
    exit 0
  with 
    | Lexer.LexFailure (pos, msg) | Semantic.SemFailure (pos, msg)
    | Codegen.CGFailure (pos, msg) -> 
      Utilities.print_diagnostic ~p:(Some pos) msg Utilities.Error;
    | Failure msg -> 
      Utilities.print_diagnostic ~p:None msg Utilities.Error;
    | Parser.Error -> let pos = lb.Lexing.lex_curr_p in
      Utilities.print_diagnostic ~p:(Some pos) "Syntax Error" Utilities.Error;
  end;
  Printf.eprintf "• Compiled Successfully: \027[1;31m✗\027[0m\n";
  exit 1;