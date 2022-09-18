let funStr_mangled fnstr pstr = 
  "fun/" ^ fnstr ^ "/" ^ pstr

let typ_of_vartype t =
  let Ast.PTR (prim, num) = t in
  let primtyp = Types.typ_of_primitive prim in
  if num = 0 then primtyp
  else Types.TYPE_pointer {typ=primtyp; dim=num; mut= true}

