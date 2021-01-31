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

let create_on_sequence ?on_sequence () =
  match on_sequence with
  | Some on_sequence -> on_sequence
  | None -> fun _ _ -> assert false (* FIXME: bind *)

let create_on_let_from_simple ?on_and on_simple_let =
  ignore on_and;
  ignore on_simple_let;
  fun _ -> assert false

let create_on_let ?on_let ?on_simple_let ?on_and () =
  match on_let with
  | Some on_let -> on_let
  | None ->
    match on_simple_let with
    | Some on_simple_let -> create_on_let_from_simple on_simple_let ?on_and
    | None -> fun _ _ _ -> assert false (* FIXME: bind *)

let create_on_match ?on_match ?on_simple_match ?on_try () =
  ignore on_match;
  ignore on_simple_match;
  ignore on_try;
  fun _ -> assert false

let create_on_try ?on_try () =
  match on_try with
  | Some on_try -> on_try
  | None -> fun _ _ -> assert false

let create_on_ifthenelse ?on_ifthenelse ?on_simple_ifthenelse ?on_simple_ifthen () =
  ignore on_ifthenelse;
  ignore on_simple_ifthenelse;
  ignore on_simple_ifthen;
  fun _ -> assert false

let create_on_while ?on_while () =
  ignore on_while;
  fun _ -> assert false

let create_on_for ?on_for () =
  ignore on_for;
  fun _ -> assert false

let create_on_assert ?on_assert ?on_assert_false () =
  ignore on_assert;
  ignore on_assert_false;
  fun _ -> assert false
