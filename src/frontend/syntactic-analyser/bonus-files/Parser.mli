
(* The type of tokens. *)

type token = 
  | T_void
  | T_true
  | T_timesequals
  | T_times
  | T_string of (string)
  | T_semicolon
  | T_rightsqbr
  | T_rightpar
  | T_rightbr
  | T_return
  | T_ref
  | T_question
  | T_plusplus
  | T_plusequals
  | T_plus
  | T_or
  | T_not
  | T_new
  | T_neq
  | T_modequals
  | T_mod
  | T_minusminus
  | T_minusequals
  | T_minus
  | T_lt
  | T_leftsqbr
  | T_leftpar
  | T_leftbr
  | T_le
  | T_int
  | T_include of (Ast.ast)
  | T_if
  | T_id of (string)
  | T_gt
  | T_ge
  | T_for
  | T_false
  | T_eq
  | T_eof
  | T_else
  | T_double
  | T_divequals
  | T_div
  | T_delete
  | T_continue
  | T_constreal of (float)
  | T_constint of (int)
  | T_constchar of (char)
  | T_comma
  | T_colon
  | T_char
  | T_byref
  | T_break
  | T_bool
  | T_assign
  | T_and
  | T_NULL

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.ast)
