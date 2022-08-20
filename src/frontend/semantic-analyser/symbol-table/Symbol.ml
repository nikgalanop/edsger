open Identifier
open Types

module H = Hashtbl.Make (
  struct
    type t = id
    let equal = (==)
    let hash = Hashtbl.hash
  end
)

type pass_mode = PASS_BY_VALUE | PASS_BY_REFERENCE

type param_status =
  | PARDEF_COMPLETE
  | PARDEF_DEFINE
  | PARDEF_CHECK

type scope = {
  sco_parent : scope option;
  sco_nesting : int;
  mutable sco_entries : entry list;
}

and variable_info = {
  variable_type   : Types.typ;
}

and function_info = {
  mutable function_isForward : bool;
  mutable function_paramlist : entry list;
  mutable function_redeflist : entry list;
  mutable function_result    : Types.typ;
  mutable function_pstatus   : param_status;
}

and parameter_info = {
  parameter_type           : Types.typ;
  parameter_mode           : pass_mode
}

and entry_info = ENTRY_none
               | ENTRY_variable of variable_info
               | ENTRY_function of function_info
               | ENTRY_parameter of parameter_info
               | ENTRY_label of bool ref

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
let forNest = ref 0

let tab = ref (H.create 0)

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
  | Some scp ->
      currentScope := scp
  | None ->
      Printf.eprintf "Cannot close the outer scope!"

exception Failure_NewEntry of entry

let newEntry id inf err =
  try
    if err then begin
      try
        let e = H.find !tab id in
        if e.entry_scope.sco_nesting = !currentScope.sco_nesting then
           raise (Failure_NewEntry e)
      with Not_found ->
        ()
    end;
    let e = {
      entry_id = id;
      entry_scope = !currentScope;
      entry_info = inf
    } in
    H.add !tab id e;
    !currentScope.sco_entries <- e :: !currentScope.sco_entries;
    e
  with Failure_NewEntry e ->
    let msg = Printf.sprintf "Duplicate Identifier %s" (id_name id) in
    failwith msg

let lookupEntry id how err =
  let scc = !currentScope in
  let lookup () =
    match how with
    | LOOKUP_CURRENT_SCOPE ->
      let e = H.find !tab id in
      if e.entry_scope.sco_nesting = scc.sco_nesting then
        e
      else
        raise Not_found
  | LOOKUP_ALL_SCOPES ->
      H.find !tab id 
  in
  if err then
    try
      lookup ()
    with Not_found ->
      (* Printf.printf "Unknown Identifier %s (First Occurrence)"
        (id_name id); *)
      H.add !tab id (no_entry id);
      raise Exit
  else
    lookup ()

let newVariable id typ err =
  let inf = {
    variable_type = typ;
  } 
  in newEntry id (ENTRY_variable inf) err

let newFunction id =
  try
    let e = lookupEntry id LOOKUP_CURRENT_SCOPE false in 
    match e.entry_info with
    | ENTRY_function inf when inf.function_isForward ->
        begin  
          inf.function_isForward <- false;
          inf.function_pstatus <- PARDEF_CHECK;
          inf.function_redeflist <- inf.function_paramlist;
        end;
        (e, true)
    | ENTRY_function inf 
      when inf.function_pstatus = PARDEF_COMPLETE ->
        (e, true)
    | _ -> 
        failwith "Duplicate Identifier."
  with Not_found ->
    let inf = {
      function_isForward = false;
      function_paramlist = [];
      function_redeflist = [];
      function_result = TYPE_none;
      function_pstatus = PARDEF_DEFINE;
    } in
    (newEntry id (ENTRY_function inf) false, false)

let newParameter id typ mode f err =
  match f.entry_info with
  | ENTRY_function inf -> begin
      match inf.function_pstatus with
      | PARDEF_DEFINE ->
          let inf_p = {
            parameter_type = typ;
            parameter_mode = mode
          } in
          begin
            try
              let e = newEntry id (ENTRY_parameter inf_p) err in
              inf.function_paramlist <- e :: inf.function_paramlist;
              e
            with _ -> 
              failwith "Named more than one parameters of the same function with the same name."
          end 
      | PARDEF_CHECK -> begin
          match inf.function_redeflist with
          | p :: ps -> begin
              inf.function_redeflist <- ps;
              match p.entry_info with
              | ENTRY_parameter inf ->
                  if not (equalType inf.parameter_type typ) then
                    failwith "Parameter type mismatch."
                  else if inf.parameter_mode != mode then
                    failwith "Parameter passing mode."
                  else
                    H.add !tab id p;
                  p
              | _ ->
                  failwith "Found a parameter that is not a parameter!"
            end
          | [] ->
              failwith "More parameters than expected."
        end
      | PARDEF_COMPLETE ->
          failwith "Cannot add a parameter to an already defined function"
    end
  | _ -> 
      failwith "Cannot add a parameter to a non-function"
      
let forwardFunction e =
  match e.entry_info with
  | ENTRY_function inf ->
      inf.function_isForward <- true
  | _ ->
      failwith "Cannot make a non-function forward"

let newLabel id err = (* Err can be omitted, but the function would not be easily readable. *)
  newEntry id (ENTRY_label (ref true)) err

let openForScope () = 
  forNest := !forNest + 1 
    
let closeForScope = function
  | None -> forNest := !forNest - 1
  | Some id -> try 
        let e = lookupEntry id LOOKUP_ALL_SCOPES true in 
        begin
        match e.entry_info with 
          | ENTRY_label b -> b := false; forNest := !forNest - 1
          | _ -> Printf.eprintf "Should not find an entry of type label with an id of a label." 
        end
      with Exit -> 
          Printf.eprintf "Cannot close scope of non-existing label"

let insideFor () = 
  !forNest > 0

let endFunctionHeader e typ =
  match e.entry_info with
  | ENTRY_function inf ->
      begin
        match inf.function_pstatus with
        | PARDEF_COMPLETE ->
            failwith "Cannot end parameters in an already defined function."
        | PARDEF_DEFINE ->
            inf.function_result <- typ;
            inf.function_paramlist <- List.rev inf.function_paramlist
        | PARDEF_CHECK ->
            if inf.function_redeflist <> [] then
              failwith "Fewer parameters than expected."
            else if not (equalType inf.function_result typ) then
              failwith "Result type mismatch."
      end;
      inf.function_pstatus <- PARDEF_COMPLETE
  | _ ->
      failwith "Cannot end parameters in a non-function."