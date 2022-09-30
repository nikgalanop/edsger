module H = Hashtbl.Make (
  struct
    type t = Identifier.id
    let equal = ( == )
    let hash = Hashtbl.hash
  end
)

type pass_mode = PASS_BY_VALUE | PASS_BY_REFERENCE

type scope = {
  sco_parent          : scope option;
  sco_nesting         : int;
  mutable sco_entries : entry list;
}

and variable_info = {
  llval : Llvm.llvalue;
}

and function_info = {
  llfun                      : Llvm.llvalue;
  function_number            : int;
  mutable function_env       : string array;
  mutable function_paramlist : pass_mode list;
}

and parameter_info = {
  parameter_mode : pass_mode
}

and label_info = { 
  stepbb : Llvm.llbasicblock;
  afterbb : Llvm.llbasicblock;
}

(* assume we only need functions, vars and parameters *)
and entry_info = ENTRY_none
               | ENTRY_variable  of variable_info
               | ENTRY_function  of function_info
               | ENTRY_parameter of parameter_info
               | ENTRY_label     of label_info

and entry = {
  entry_id    : Identifier.id;
  entry_scope : scope;
  entry_info  : entry_info
}

type lookup_type = LOOKUP_CURRENT_SCOPE | LOOKUP_ALL_SCOPES

let the_outer_scope = {
  sco_parent = None;
  sco_nesting = 0;
  sco_entries = [];
}

let no_entry id = {
  entry_id = id;
  entry_scope = the_outer_scope;
  entry_info = ENTRY_none
}

let currentScope = ref the_outer_scope

let inOuterScope () = 
  !currentScope.sco_nesting = 0

let nestingLevel () = 
  !currentScope.sco_nesting

let tab = ref (H.create 0)
let count = ref (H.create 50)

let loop_stack = Stack.create ()

let initSymbolTable size =
  tab := H.create size;
  currentScope := the_outer_scope

let openScope () =
  let sco = {
    sco_parent = Some !currentScope;
    sco_nesting = !currentScope.sco_nesting + 1;
    sco_entries = [];
  } in
  currentScope := sco

let closeScope () = 
  let sco = !currentScope in
  let manyentry e = H.remove !tab e.entry_id in
  List.iter manyentry sco.sco_entries;
  match sco.sco_parent with
  | Some scp -> currentScope := scp
  | None -> Printf.eprintf "Cannot close the outer scope!"

let newEntry id inf = 
  let e = {
    entry_id = id;
    entry_scope = !currentScope;
    entry_info = inf
  } in 
  H.add !tab id e;
  !currentScope.sco_entries <- e :: !currentScope.sco_entries;
  e

let lookupEntry id how err = 
  let scc = !currentScope in
  let lookup () = 
    match how with
    | LOOKUP_CURRENT_SCOPE -> 
      let e = H.find !tab id in
      if e.entry_scope.sco_nesting = scc.sco_nesting then e
      else raise Not_found
    | LOOKUP_ALL_SCOPES ->
      H.find !tab id
  in 
  if err then
    try lookup ()
    with Not_found -> 
      H.add !tab id (no_entry id);
      raise Exit
  else lookup ()

let newVariable id llval =  
  let inf = {llval} in 
  newEntry id (ENTRY_variable inf)

let getCounter id = 
  try 
    let c = H.find !count id in
    !c
  with Not_found -> -1
   
let updateCounter id = 
  try  
    let c = H.find !count id in
    c := !c + 1; !c
  with Not_found ->
    H.add !count id (ref 0);
    0

let newFunction id llv = 
  try
    let e = lookupEntry id LOOKUP_CURRENT_SCOPE false in
    match e.entry_info with
    | ENTRY_function inf -> (e, true)
    | _ -> failwith "Duplicate Identifier."
  with Not_found -> 
    let num = updateCounter id in
    let inf = {
      llfun = llv;
      function_number = num;
      function_env = [||];
      function_paramlist = [];
    } in
    (newEntry id (ENTRY_function inf), false)

let newParameter mode f = 
  match f.entry_info with
  | ENTRY_function inf -> begin 
      inf.function_paramlist <- mode :: inf.function_paramlist;
    end
  | _ -> failwith "Cannot add a parameter to a non-function"

let newLabel id stepbb afterbb = 
  let inf = {stepbb; afterbb} in 
  newEntry id (ENTRY_label inf)

let pushLoop stepbb afterbb = 
  let inf = {stepbb; afterbb} in
  Stack.push inf loop_stack

let peekLoop () = (* We only use this after a push. *)
  Stack.top loop_stack

let popLoop () = 
  ignore @@ Stack.pop_opt loop_stack

let setEnv f env = 
  match f.entry_info with 
  | ENTRY_function inf -> 
    inf.function_env <- Array.of_list env
  | _ -> failwith "Cannot set env of non-function."

let endFunctionHeader e =
  match e.entry_info with
  | ENTRY_function inf ->
    begin
      inf.function_paramlist <- List.rev inf.function_paramlist
    end;
  | _ -> failwith "Cannot end parameters in a non-function."
