type id = string Hashcons.hash_consed

module Hid = Hashcons.Make (
  struct
    type t = string
    let equal = (=)
    let hash = Hashtbl.hash
  end
)

let id_make = Hashcons.register_hcons Hid.f ()
let id_name = Hashcons.hash_value

let pretty_id ppf id =
  Format.fprintf ppf "%s" (id_name id)

let id_of_func n pstr = 
  id_make @@ "fun_" ^ n ^ "_" ^ pstr 
let id_of_var n = 
  id_make @@ "var_" ^ n
let id_of_label l = 
  id_make @@ "label_" ^ l
