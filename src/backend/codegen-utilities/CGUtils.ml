module StringSet = Set.Make(String)

let get_ast_param_name = function 
  | Ast.BYVAL (_, vn) | Ast.BYREF (_, vn) -> vn

let funStr_mangled fnstr pstr num = 
  let name = Printf.sprintf "%s_%s_%d" fnstr pstr num in 
  let cond1 = CGSymbol.inOuterScope () in
  let cond2 = fnstr = "main" in
  let cond3 = pstr = "" in
  if (cond1 && cond2 && cond3) then "main" else name
