open Migrate_parsetree
open OCaml_411.Ast
open Ast_mapper
open Asttypes
open Parsetree

let expr mapper = function
  | { pexp_desc =
        Pexp_extension (
          {txt="nop"; _},
          PStr [ {pstr_desc = Pstr_eval (expr, _); _} ]
        );
      _ }
    ->
    default_mapper.expr mapper expr

  | expr -> default_mapper.expr mapper expr

let mapper = { default_mapper with expr }

let () =
  Driver.register ~name:"ppx_nop" ~args:[] Versions.ocaml_411
    (fun _config _cookies -> mapper)
