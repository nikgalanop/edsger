type mode = Warning | Error;;

let starting_text =
    function 
    | Error -> "31mError"
    | Warning -> "35mWarning"

let print_diagnostic ~(p : Lexing.position option) msg mode = 
    let txt = starting_text mode in
    match p with 
    | None -> Printf.eprintf "\027[1;%s:\027[0m %s\n" txt msg;
    | Some pos -> let line_pos = (pos.pos_cnum - pos.pos_bol + 1) in
                  Printf.eprintf "\027[1;%s (File: '%s' - Line %d, Column %d): \027[0m%s\n"
                                txt pos.pos_fname pos.pos_lnum line_pos msg;

