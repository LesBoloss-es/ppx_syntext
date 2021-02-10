open Migrate_parsetree
open OCaml_411.Ast
open Asttypes
open Parsetree

type t = {
  on_let        : rec_flag -> value_binding list -> expression -> expression ;
  on_match      : expression -> case list -> expression ;
  on_try        : expression -> case list -> expression ;
  on_ifthenelse : expression -> expression -> expression option -> expression ;
  on_sequence   : expression -> expression -> expression ;
  on_while      : expression -> expression -> expression ;
  on_for        : pattern -> expression -> expression -> direction_flag -> expression -> expression ;
  on_assert     : expression -> expression ;
}

val create_on_sequence :
  ?on_sequence:(expression -> expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  expression -> expression -> expression

val create_on_let :
  ?on_let:(rec_flag -> value_binding list -> expression -> expression) ->
  ?on_simple_let:(pattern -> expression -> expression -> expression) ->
  ?on_and:(expression -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  rec_flag -> value_binding list -> expression -> expression

val create_on_match :
  ?on_match:(expression -> case list -> expression) ->
  ?on_simple_match:(expression -> case list -> expression) ->
  on_try:(expression -> case list -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  expression -> case list -> expression

val create_on_try :
  ?on_try:(expression -> case list -> expression) ->
  ?on_return_error:(expression -> expression) ->
  ?on_bind_error:(expression -> expression -> expression) ->
  unit ->
  expression -> case list -> expression

val create_on_ifthenelse :
  ?on_ifthenelse:(expression -> expression -> expression option -> expression) ->
  ?on_simple_ifthen:(expression -> expression -> expression) ->
  ?on_simple_ifthenelse:(expression -> expression -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  expression -> expression -> expression option -> expression

val create_on_while :
  ?on_while:(expression -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  expression -> expression -> expression

val create_on_for :
  ?on_for:(pattern -> expression -> expression -> direction_flag -> expression -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  unit ->
  pattern -> expression -> expression -> direction_flag -> expression -> expression

val create_on_assert :
  ?on_assert:(expression -> expression) ->
  ?on_assert_false:(unit -> expression) ->
  ?on_return:(expression -> expression) ->
  ?on_bind:(expression -> expression -> expression) ->
  ?on_return_error:(expression -> expression) ->
  unit ->
  expression -> expression
