type printmode = Warning | Error

let starting_text = function 
    | Error -> "31mError"
    | Warning -> "35mWarning"

let print_diagnostic ~(p : Lexing.position option) msg mode = 
    let txt = starting_text mode in
    match p with 
    | None -> Printf.eprintf "\027[1;%s:\027[0m %s\n" txt msg;
    | Some pos -> let line_pos = (pos.pos_cnum - pos.pos_bol + 1) in
                  Printf.eprintf "\027[1;%s (File '%s' - Line %d, Column %d): \027[0m%s\n"
                                txt pos.pos_fname pos.pos_lnum line_pos msg

let get_base_dir () = 
    try 
        Sys.getenv "EDS_BASE_DIR"
    with | _ -> 
        print_diagnostic ~p:None "Base directory not configured." Error;
        exit 1

let lib_base_dir = get_base_dir ()

let static_lib_dir () = 
    let fn = ref "edsgerlib.a" in 
    if (not @@ Sys.file_exists !fn) then begin
        fn := lib_base_dir ^ !fn;
        if (not @@ Sys.file_exists !fn) then begin
            let msg = Printf.sprintf "Did not find the static library 'edsgerlib.a' \
                neither in the current directory or in %s" lib_base_dir in 
            print_diagnostic ~p:None msg Error; 
            exit 1
        end 
    end;
    !fn 

let default_lib_header fn = 
    Printf.sprintf "%s/lib-headers/%s" lib_base_dir fn 