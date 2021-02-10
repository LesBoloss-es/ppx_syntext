open Migrate_parsetree
open OCaml_411.Ast
open Ast_helper

let on_sequence = Exp.sequence

let on_simple_let x e1 e2 = [%expr let [%p x] = [%e e1] in [%e e2]]
let on_and e1 e2 = [%expr ([%e e1], [%e e2])]

let on_simple_ifthen e1 e2 = [%expr if [%e e1] then [%e e2]]
let on_simple_ifthenelse e1 e2 e3 = [%expr if [%e e1] then [%e e2] else [%e e3]]

let on_simple_match = Exp.match_

let on_try = Exp.try_

let on_assert = Exp.assert_
let on_assert_false () = [%expr assert false]

let on_while = Exp.while_
let on_for = Exp.for_

let () = Ppx_syntext.(register (
    create "ppx_nop_simple"
      ~applies_on:"nop"
      ~on_sequence:Exp.sequence
      ~on_simple_let ~on_and
      ~on_simple_ifthen ~on_simple_ifthenelse
      ~on_simple_match
      ~on_try
      ~on_assert ~on_assert_false
      ~on_while
      ~on_for
  ))
