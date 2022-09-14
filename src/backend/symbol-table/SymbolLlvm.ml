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
  mutable function_isForward : bool;
  mutable function_paramlist : entry list;
  mutable function_result    : Types.typ;
 }
and parameter_info = {
  parameter_type : Types.typ;
  parameter_mode : pass_mode;
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

let tab = ref (H.create 0)

let loop_stack : (label_info list ref) = ref []

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
      (* Printf.printf "Unknown Identifier %s (First Occurrence)"
        (id_name id); *)
      H.add !tab id (no_entry id);
      raise Exit
  else lookup ()

let newVariable id llv = 
  let inf = {
    llval = llv;
  } in 
  newEntry id (ENTRY_variable inf)

let newFunction id llv = 
  try
    let e = lookupEntry id LOOKUP_CURRENT_SCOPE false in
    match e.entry_info with
    | ENTRY_function inf when inf.function_isForward ->
      inf.function_isForward <- false;
      (e, true)
    | ENTRY_function inf -> (e, true)
    | _ -> failwith "Duplicate Identifier."
  with Not_found -> 
    let inf = {
      llfun = llv;
      function_isForward = false;
      function_paramlist = [];
      function_result = Types.TYPE_none;
    } in
    (newEntry id (ENTRY_function inf), false)

let newParameter id typ mode f = 
  match f.entry_info with
  | ENTRY_function inf -> begin
    let inf_p = {
      parameter_type = typ;
      parameter_mode = mode;
    } in
    let e = newEntry id (ENTRY_parameter inf_p) in 
      inf.function_paramlist <- e :: inf.function_paramlist;
      e
    end
  | _ -> failwith "Cannot add a parameter to a non-function"

let forwardFunction e = 
  match e.entry_info with
  | ENTRY_function inf -> 
    inf.function_isForward <- true
  | _ -> failwith "Cannot make a non-function forward"

let newLabel id step_bb after_bb = 
  let inf = {
    stepbb = step_bb;
    afterbb = after_bb;
  } in 
  newEntry id (ENTRY_label inf)

let pushLoop step_bb after_bb = 
  let inf = {
    stepbb = step_bb;
    afterbb = after_bb;
  } in
  loop_stack := inf :: !loop_stack

let peekLoop () =
  match !loop_stack with
  | h::t -> Some h
  | [] -> None

let popLoop () = 
  match !loop_stack with
  | h::t -> loop_stack := t
  | [] -> failwith "cannot pop from empty stack,"

let endFunctionHeader e typ =
  match e.entry_info with
  | ENTRY_function inf ->
    begin
      inf.function_result <- typ;
      inf.function_paramlist <- List.rev inf.function_paramlist
    end;
  | _ -> failwith "Cannot end parameters in a non-function."
