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
  id_make @@ "fun/" ^ n ^ "/" ^ pstr 
let id_of_var n = 
  id_make @@ "var/" ^ n
let id_of_label l = 
  id_make @@ "label/" ^ l

let ent_name_of_id id = (* Should change the separator from _ to something else in the following 3 functions. *)
  let n = id_name id in 
  let _ :: ename :: _ = String.split_on_char '/' n in 
  ename
