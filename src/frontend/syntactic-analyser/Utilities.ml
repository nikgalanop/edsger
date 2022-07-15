type mode = Warning | Error;;

let starting_text =
    function 
    | Error -> "31mError"
    | Warning -> "35mWarning"

let print_msg (pos : Lexing.position) msg mode = 
    let line_pos = (pos.pos_cnum - pos.pos_bol + 1) in
    let txt = starting_text mode in
    Printf.eprintf "\027[1;%s (File: '%s' - Line %d, Column %d): \027[0m%s\n"
                    txt pos.pos_fname pos.pos_lnum line_pos msg

