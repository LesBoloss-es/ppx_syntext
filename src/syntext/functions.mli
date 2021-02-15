open Migrate_parsetree
open OCaml_411.Ast
open Asttypes
open Parsetree

type on_assert = expression -> expression
type on_for = pattern -> expression -> expression -> direction_flag -> expression -> expression
type on_ifthenelse = expression -> expression -> expression option -> expression
type on_let = rec_flag -> value_binding list -> expression -> expression
type on_match = expression -> case list -> expression
type on_sequence = expression -> expression -> expression
type on_try = on_match
type on_while = on_sequence

type t = {
  on_assert     : on_assert ;
  on_for        : on_for ;
  on_ifthenelse : on_ifthenelse ;
  on_let        : on_let ;
  on_match      : on_match ;
  on_sequence   : on_sequence ;
  on_try        : on_try ;
  on_while      : on_while ;
}

val create_on_assert :
  ?on_assert:(expression -> expression) ->
  ?on_assert_false:(unit -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  ?on_return_error:(expression -> expression) ->
  unit ->
  on_assert

val create_on_for :
  ?on_for:(pattern -> expression -> expression -> direction_flag -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  on_for

val create_on_ifthenelse :
  ?on_ifthenelse:(expression -> expression -> expression option -> expression) ->
  ?on_simple_ifthen:(expression -> expression -> expression) ->
  ?on_simple_ifthenelse:(expression -> expression -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  on_ifthenelse

val create_on_let :
  ?on_let:(rec_flag -> value_binding list -> expression -> expression) ->
  ?on_simple_let:(pattern -> expression -> expression -> expression) ->
  ?on_and:(expression -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  on_let

val create_on_match :
  ?on_match:(expression -> case list -> expression) ->
  ?on_simple_match:(expression -> case list -> expression) ->
  on_try:(expression -> case list -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  on_match

val create_on_sequence :
  ?on_sequence:(expression -> expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  on_sequence

val create_on_try :
  ?on_try:(expression -> case list -> expression) ->
  ?on_return_error:(expression -> expression) ->
  ?on_bind_error:(expression -> expression -> expression) ->
  unit ->
  on_try

val create_on_while :
  ?on_while:(expression -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  on_while
