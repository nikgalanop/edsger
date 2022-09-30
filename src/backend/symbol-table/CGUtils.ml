module StringSet = Set.Make(String)

let get_ast_param_name = function 
  | Ast.BYVAL (_, vn) | Ast.BYREF (_, vn) -> vn

let funStr_mangled fnstr pstr num = 
  let num' = string_of_int num in 
  let name = fnstr ^ "_" ^ pstr ^ "_" ^ num' in 
  let cond1 = CGSymbol.inOuterScope () in
  let cond2 = fnstr = "main" in 
  let cond3 = pstr = "" in
  if (cond1 && cond2 && cond3) then "main" else name

let filter_env ps env = 
  let set = ref StringSet.empty in 
  let add p = 
    let n = get_ast_param_name p in 
    set := StringSet.add n !set  
  in List.iter add ps;
  let not_exists p = 
    let n = get_ast_param_name p in 
    not @@ StringSet.mem n !set 
  in Some (List.filter not_exists env)

let typ_of_vartype t =
  let Ast.PTR (prim, num) = t in
  let primtyp = Types.typ_of_primitive prim in
  if num = 0 then primtyp
  else Types.TYPE_pointer {typ = primtyp; 
    dim = num; mut = true}