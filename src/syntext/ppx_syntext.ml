open Migrate_parsetree
open OCaml_411.Ast
open Ast_mapper
open Asttypes
open Parsetree

open Functions

(* =============================== [ Mapper ] =============================== *)

let mapper_of_functions applies functions =
  let expr mapper = function
    | { pexp_desc =
          Pexp_extension (
            {txt; loc},
            PStr [ {pstr_desc = Pstr_eval (expr, _); _} ]
          );
        _ }
      when applies txt
      ->
      Ast_helper.with_default_loc loc @@ fun () ->
      let expr =
        match expr.pexp_desc with
        | Pexp_sequence (e1, e2) -> functions.on_sequence e1 e2
        | Pexp_let (rf, vbs, e) -> functions.on_let rf vbs e
        | Pexp_match (e, cases) -> functions.on_match e cases
        | Pexp_try (e, cases) -> functions.on_try e cases
        | Pexp_ifthenelse (e1, e2, e3) -> functions.on_ifthenelse e1 e2 e3
        | Pexp_assert e -> functions.on_assert e
        | Pexp_while (e1, e2) -> functions.on_while e1 e2
        | Pexp_for (i, e1, e2, dir, e3) -> functions.on_for i e1 e2 dir e3
        | _ -> expr
      in
      default_mapper.expr mapper expr
    | expr -> default_mapper.expr mapper expr
  in
  { default_mapper with expr }

(* ============================= [ Extension ] ============================== *)

module Helpers = Helpers

type t = {
  name : string ;
  mapper : mapper ;
}

let create_applies ?applies_on name =
  (match applies_on with
   | Some applies_on -> applies_on
   | None -> name)
  |> (fun r -> "(syntext.)?(" ^ r ^ ")")
  |> SimpleRegexp.from_string
  |> SimpleRegexp.matches

let create
    (* Functions *)
    ?on_sequence
    ?on_let             ?on_simple_let ?on_and
    ?on_match           ?on_simple_match
    ?on_try
    ?on_ifthenelse      ?on_simple_ifthenelse ?on_simple_ifthen
    ?on_while
    ?on_for
    ?on_assert          ?on_assert_false

    (* Monadic functions *)
    ?on_return ?on_bind
    ?on_return_error ?on_bind_error

    (* Applies on & Name *)
    ?applies_on
    name
  =
  let functions =
    let on_try = create_on_try ?on_try ?on_return_error ?on_bind_error () in
    {
    (*on_*          = create_on_*          ?on_*          ............ ?on_simple_* ............. ?on_return ?on_bind () *)
      on_let        = create_on_let        ?on_let        ?on_simple_let ?on_and                  ?on_return ?on_bind () ;
      on_match      = create_on_match      ?on_match      ?on_simple_match ~on_try                           ?on_bind () ;
      on_try                                                                                                             ;
      on_ifthenelse = create_on_ifthenelse ?on_ifthenelse ?on_simple_ifthenelse ?on_simple_ifthen ?on_return ?on_bind () ;
      on_sequence   = create_on_sequence   ?on_sequence                                                      ?on_bind () ;
      on_while      = create_on_while      ?on_while                                              ?on_return ?on_bind () ;
      on_for        = create_on_for        ?on_for                                                ?on_return ?on_bind () ;
      on_assert     = create_on_assert     ?on_assert     ?on_assert_false       ?on_return ?on_bind ?on_return_error () ;
    }
  in
  let applies = create_applies ?applies_on name in
  let mapper = mapper_of_functions applies functions in
  { name ; mapper }

let register ext =
  Migrate_parsetree.(
    Driver.register
      ~name:ext.name
      Versions.ocaml_411
      (fun _config _cookies -> ext.mapper)
  )
