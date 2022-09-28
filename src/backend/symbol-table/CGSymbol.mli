(* Symbol table *)

type pass_mode = PASS_BY_VALUE | PASS_BY_REFERENCE

type scope = {
  sco_parent : scope option;
  sco_nesting : int;
  mutable sco_entries : entry list;
}

and variable_info = {                         (******* Μεταβλητή *******)
  llval   : Llvm.llvalue;                (**)
}

and function_info = {                         (******* Συνάρτηση  *******)
  llfun                      : Llvm.llvalue;
  function_number            : int;
  mutable function_paramlist : pass_mode list;    (* List Parameters        *)
}

and parameter_info = {
  parameter_mode : pass_mode;
}

and label_info = { 
  stepbb : Llvm.llbasicblock;
  afterbb : Llvm.llbasicblock;
}

and entry_info = ENTRY_none
               | ENTRY_variable of variable_info
               | ENTRY_function of function_info
               | ENTRY_parameter of parameter_info
               | ENTRY_label of label_info

and entry = {
  entry_id    : Identifier.id;
  entry_scope : scope;
  entry_info  : entry_info
}

type lookup_type = LOOKUP_CURRENT_SCOPE | LOOKUP_ALL_SCOPES

val currentScope : scope ref              (* Τρέχουσα Εμβέλεια *)
val inOuterScope : unit -> bool

val nestingLevel : unit -> int 

val initSymbolTable  : int -> unit
val openScope        : unit -> unit
val closeScope       : unit -> unit
val newVariable      : Identifier.id -> Llvm.llvalue -> entry
val getCounter       : Identifier.id -> int
val newFunction      : Identifier.id -> Llvm.llvalue -> entry * bool
val newParameter     : pass_mode -> entry -> unit
val newLabel         : Identifier.id -> Llvm.llbasicblock -> Llvm.llbasicblock -> entry

val endFunctionHeader    : entry -> unit
val lookupEntry          : Identifier.id -> lookup_type -> bool -> entry

val pushLoop  : Llvm.llbasicblock -> Llvm.llbasicblock -> unit
val peekLoop  : unit -> label_info
val popLoop   : unit -> unit