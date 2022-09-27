let funStr_mangled fnstr pstr num = 
  let num' = string_of_int num in 
  let name = fnstr ^ "_" ^ pstr ^ "_" ^ num' in 
  if (name = "main__0") then "main" else name

let typ_of_vartype t =
  let Ast.PTR (prim, num) = t in
  let primtyp = Types.typ_of_primitive prim in
  if num = 0 then primtyp
  else Types.TYPE_pointer {typ = primtyp; 
    dim = num; mut = true}