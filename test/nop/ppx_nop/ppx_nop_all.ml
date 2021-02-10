open Migrate_parsetree
open OCaml_411.Ast
open Ast_helper

let () = Ppx_syntext.(register (
    create "ppx_nop_all"
      ~applies_on:"nop"
      ~on_sequence:Exp.sequence
      ~on_let:Exp.let_
      ~on_ifthenelse:Exp.ifthenelse
      ~on_match:Exp.match_
      ~on_try:Exp.try_
      ~on_assert:Exp.assert_
      ~on_while:Exp.while_
      ~on_for:Exp.for_
  ))
