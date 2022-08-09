(* Symbol table *)

type pass_mode = PASS_BY_VALUE | PASS_BY_REFERENCE

type param_status =
  | PARDEF_COMPLETE                             (* Πλήρης Ορισμός     *)
  | PARDEF_DEFINE                               (* Εν μέσω ορισμού    *)
  | PARDEF_CHECK                                (* Εν μέσω ελέγχου   *)

type scope = {
  sco_parent : scope option;
  sco_nesting : int;
  mutable sco_entries : entry list;
  mutable sco_negofs : int
}

and variable_info = {                         (******* Μεταβλητή *******)
  variable_type   : Types.typ;                (* Τύπος                 *)
  variable_offset : int                       (* Offset στο Ε.Δ.       *)
}

and function_info = {                         (******* Συνάρτηση  *******)
  mutable function_isForward : bool;          (* Forward Function       *)
  mutable function_paramlist : entry list;    (* List Parameters        *)
  mutable function_redeflist : entry list;    (* Λίστα Παραμέτρων (2η)  *)
  mutable function_result    : Types.typ;     (* Function Result        *)
  mutable function_pstatus   : param_status;  (* Κατάσταση Παραμέτρων   *)
  mutable function_initquad  : int            (* Αρχική Τετράδα         *)
}

and parameter_info = {                        (****** Παράμετρος *******)
  parameter_type           : Types.typ;       (* Τύπος                 *)
  mutable parameter_offset : int;             (* Offset στο Ε.Δ.       *)
  parameter_mode           : pass_mode        (* Τρόπος Περάσματος     *)
}

and temporary_info = {                        (** Προσωρινή Μεταβλητή **)
  temporary_type   : Types.typ;               (* Τύπος                 *)
  temporary_offset : int                      (* Offset στο Ε.Δ.       *)
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

val currentScope : scope ref              (* Τρέχουσα Εμβέλεια         *)
val quadNext : int ref                    (* Αριθμός Επόμενης Τετράδας *)
val tempNumber : int ref                  (* Αρίθμηση των Temporaries  *)

val initSymbolTable  : int -> unit
val openScope        : unit -> unit
val closeScope       : unit -> unit
val openForScope     : unit -> unit
val closeForScope    : Identifier.id option -> unit
val newVariable      : Identifier.id -> Types.typ -> bool -> entry
val newFunction      : decl : bool -> Identifier.id -> entry * bool
val newParameter     : Identifier.id -> Types.typ -> pass_mode ->
                                        entry -> bool -> entry
val newTemporary     : Types.typ -> entry
val newLabel         : Identifier.id -> bool -> entry

val registerFunctionType : Types.typ -> unit
val endFunctionHeader : entry -> Types.typ -> unit
val lookupEntry       : Identifier.id -> lookup_type -> 
                                      all : bool -> bool -> entry list
val insideFor         : unit -> bool
val lookupFunctionType : unit -> Types.typ

val start_positive_offset : int   (* Αρχικό Θετικό Offset στο Ε.Δ.   *)
val start_negative_offset : int   (* Αρχικό Αρνητικό Offset στο Ε.Δ. *)
