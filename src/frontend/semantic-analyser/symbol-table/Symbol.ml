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
  mutable sco_negofs : int
}

and variable_info = {
  variable_type   : Types.typ;
  variable_offset : int
}

and function_info = {
  mutable function_isForward : bool;
  mutable function_paramlist : entry list;
  mutable function_redeflist : entry list;
  mutable function_result    : Types.typ;
  mutable function_pstatus   : param_status;
  mutable function_initquad  : int
}

and parameter_info = {
  parameter_type           : Types.typ;
  mutable parameter_offset : int;
  parameter_mode           : pass_mode
}

and temporary_info = {
  temporary_type   : Types.typ;
  temporary_offset : int
}

and entry_info = ENTRY_none
               | ENTRY_variable of variable_info
               | ENTRY_function of function_info
               | ENTRY_parameter of parameter_info
               | ENTRY_temporary of temporary_info
               | ENTRY_label of bool ref

and entry = {
  entry_id    : Identifier.id;
  entry_scope : scope;
  entry_info  : entry_info
}

type lookup_type = LOOKUP_CURRENT_SCOPE | LOOKUP_ALL_SCOPES

let start_positive_offset = 8
let start_negative_offset = 0

let the_outer_scope = {
  sco_parent = None;
  sco_nesting = 0;
  sco_entries = [];
  sco_negofs = start_negative_offset
}

let no_entry id = {
  entry_id = id;
  entry_scope = the_outer_scope;
  entry_info = ENTRY_none
}

let currentScope = ref the_outer_scope
let quadNext = ref 1
let tempNumber = ref 1
let forScope = ref false
let currentFunctionType = ref (Types.TYPE_proc)

let tab = ref (H.create 0)

let initSymbolTable size =
   tab := H.create size;
   currentScope := the_outer_scope

let openScope () =
  let sco = {
    sco_parent = Some !currentScope;
    sco_nesting = !currentScope.sco_nesting + 1;
    sco_entries = [];
    sco_negofs = start_negative_offset
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
    Printf.printf "Duplicate Identifier %s" (id_name id);
    e

let lookupEntry id how ~all err =
  let scc = !currentScope in
  let lookup () =
    match how with
    | LOOKUP_CURRENT_SCOPE ->
        let in_current e = (e.entry_scope.sco_nesting = scc.sco_nesting) in
        if (all) then 
          let e = H.find !tab id in
          if (in_current e) then [e]
          else raise Not_found
        else 
            let le = List.filter in_current @@ H.find_all !tab id in 
            if (le = []) then raise Not_found 
            else le
    | LOOKUP_ALL_SCOPES when all -> H.find_all !tab id
    | LOOKUP_ALL_SCOPES -> [H.find !tab id]
  in
  if err then
    try
      lookup ()
    with Not_found ->
      Printf.printf "Unknown Identifier %s (First Occurrence)"
        (id_name id);
      (* put it in, so we don't see more errors *)
      H.add !tab id (no_entry id);
      raise Exit
  else
    lookup ()

let newVariable id typ err =
  !currentScope.sco_negofs <- !currentScope.sco_negofs - sizeOfType typ;
  let inf = {
    variable_type = typ;
    variable_offset = !currentScope.sco_negofs
  } in
  newEntry id (ENTRY_variable inf) err

let newFunction ~decl id =
  try
    let e = List.hd @@ lookupEntry id LOOKUP_CURRENT_SCOPE ~all:false false in 
    (* Incorrect. Should also have the same parameters AND return type. *)
    match e.entry_info with
    | ENTRY_function inf when inf.function_isForward ->
        if not decl then begin  
          inf.function_isForward <- false;
          inf.function_pstatus <- PARDEF_CHECK;
          inf.function_redeflist <- inf.function_paramlist;
        end;
        (e, true)
    | ENTRY_function inf 
      when inf.function_pstatus = PARDEF_COMPLETE ->
        (e, true)
    | _ -> let msg = Printf.sprintf "A non-function has the same identifier as a function: %s" (id_name id)
      in failwith msg
  with Not_found ->
    let inf = {
      function_isForward = decl;
      function_paramlist = [];
      function_redeflist = [];
      function_result = TYPE_none;
      function_pstatus = PARDEF_DEFINE;
      function_initquad = 0
    } in
    (newEntry id (ENTRY_function inf) false, false)

let newParameter id typ mode f err =
  match f.entry_info with
  | ENTRY_function inf -> begin
      match inf.function_pstatus with
      | PARDEF_DEFINE ->
          let inf_p = {
            parameter_type = typ;
            parameter_offset = 0;
            parameter_mode = mode
          } in
          let e = newEntry id (ENTRY_parameter inf_p) err in
          inf.function_paramlist <- e :: inf.function_paramlist;
          e
      | PARDEF_CHECK -> begin
          match inf.function_redeflist with
          | p :: ps -> begin
              inf.function_redeflist <- ps;
              match p.entry_info with
              | ENTRY_parameter inf ->
                  if not (equalType inf.parameter_type typ) then
                    Printf.printf "Parameter type mismatch in redeclaration \
                           of function %s" (id_name f.entry_id)
                  else if inf.parameter_mode != mode then
                    Printf.printf "Parameter passing mode mismatch in redeclaration \
                           of function %s" (id_name f.entry_id)
                  else if p.entry_id != id then
                    Printf.printf "Parameter name mismatch in redeclaration \
                           of function %s" (id_name f.entry_id)
                  else
                    H.add !tab id p;
                  p
              | _ ->
                  Printf.printf "I found a parameter that is not a parameter!";
                  raise Exit
            end
          | [] ->
              Printf.printf "More parameters than expected in redeclaration \
                     of function %s" (id_name f.entry_id);
              raise Exit
        end
      | PARDEF_COMPLETE ->
          Printf.eprintf "Cannot add a parameter to an already defined function";
          raise Exit
    end
  | _ ->
      Printf.eprintf "Cannot add a parameter to a non-function";
      raise Exit

let newTemporary typ =
  let id = id_make ("$" ^ string_of_int !tempNumber) in
  !currentScope.sco_negofs <- !currentScope.sco_negofs - sizeOfType typ;
  let inf = {
    temporary_type = typ;
    temporary_offset = !currentScope.sco_negofs
  } in
  incr tempNumber;
  newEntry id (ENTRY_temporary inf) false

let newLabel id err = (* Err can be omitted, but the function would not be easily readable. *)
    newEntry id (ENTRY_label (ref true)) err

let openForScope () = 
  forScope := true

let closeForScope = function
  | None -> forScope := false
  | Some id -> try 
        let e = List.hd @@ lookupEntry id LOOKUP_ALL_SCOPES ~all:false true in 
        begin
        match e.entry_info with 
          | ENTRY_label b -> b := false; forScope := false
          | _ -> Printf.eprintf "Should not find an entry of type label with an id of a label." 
        end
      with Exit -> 
          Printf.eprintf "Cannot close scope of non-existing label"

let insideFor () = 
  !forScope

let registerFunctionType ft = 
  currentFunctionType := ft

let lookupFunctionType () = 
  !currentFunctionType

let endFunctionHeader e typ =
  match e.entry_info with
  | ENTRY_function inf ->
      begin
        match inf.function_pstatus with
        | PARDEF_COMPLETE ->
            Printf.eprintf "Cannot end parameters in an already defined function"
        | PARDEF_DEFINE ->
            inf.function_result <- typ;
            let offset = ref start_positive_offset in
            let fix_offset e =
              match e.entry_info with
              | ENTRY_parameter inf ->
                  inf.parameter_offset <- !offset;
                  let size =
                    match inf.parameter_mode with
                    | PASS_BY_VALUE     -> sizeOfType inf.parameter_type
                    | PASS_BY_REFERENCE -> 2 in
                  offset := !offset + size
              | _ ->
                  Printf.eprintf "Cannot fix offset to a non parameter" in
            List.iter fix_offset inf.function_paramlist;
            inf.function_paramlist <- List.rev inf.function_paramlist
        | PARDEF_CHECK ->
            if inf.function_redeflist <> [] then
              Printf.printf "Fewer parameters than expected in redeclaration \
                     of function %s" (id_name e.entry_id);
            if not (equalType inf.function_result typ) then
              Printf.printf "Result type mismatch in redeclaration of function %s"
                    (id_name e.entry_id);
      end;
      inf.function_pstatus <- PARDEF_COMPLETE
  | _ ->
      Printf.eprintf "Cannot end parameters in a non-function"