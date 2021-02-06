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
      ignore loc;
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

let wrap_applies_on applies_on =
  let syntext = "syntext." in
  let l_syntext = String.length syntext in
  fun txt ->
    let l_txt = String.length txt in
    let txt =
      if l_txt >= l_syntext && String.sub txt 0 l_syntext = syntext then
        String.sub txt l_syntext (l_txt - l_syntext)
      else
        txt
    in
    applies_on txt

let create_applies_from_regexp regexp =
  let regexp = Str.regexp regexp in
  wrap_applies_on (fun txt -> Str.string_match regexp txt 0)

let create_applies ?applies_on ?applies_on_regexp name =
  match applies_on, applies_on_regexp with
  | Some _          , Some _                 -> assert false
  | Some applies_on , None                   -> wrap_applies_on applies_on
  | None            , Some applies_on_regexp -> create_applies_from_regexp applies_on_regexp
  | None            , None                   -> create_applies_from_regexp name

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
    ?on_return ?on_bind

    (* Applies on & Name *)
    ?applies_on         ?applies_on_regexp
    name
  =
  let functions = {
    (*on_*          = create_on_*          ?on_*          ............ ?on_simple_* ............. ?on_return ?on_bind () *)
      on_let        = create_on_let        ?on_let        ?on_simple_let ?on_and                  ?on_return ?on_bind () ;
      on_match      = create_on_match      ?on_match      ?on_simple_match ?on_try                                    () ;
      on_try        = create_on_try        ?on_try                                                                    () ;
      on_ifthenelse = create_on_ifthenelse ?on_ifthenelse ?on_simple_ifthenelse ?on_simple_ifthen                     () ;
      on_sequence   = create_on_sequence   ?on_sequence                                                      ?on_bind () ;
      on_while      = create_on_while      ?on_while                                                                  () ;
      on_for        = create_on_for        ?on_for                                                                    () ;
      on_assert     = create_on_assert     ?on_assert     ?on_assert_false                                            () ;
    }
  in
  let applies = create_applies ?applies_on ?applies_on_regexp name in
  let mapper = mapper_of_functions applies functions in
  { name ; mapper }

let register ext =
  Migrate_parsetree.(
    Driver.register
      ~name:ext.name
      Versions.ocaml_411
      (fun _config _cookies -> ext.mapper)
  )
