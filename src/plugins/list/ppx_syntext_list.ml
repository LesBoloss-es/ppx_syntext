open Migrate_parsetree
open OCaml_411.Ast

let on_return x =
  [%expr [[%e x]]]

let on_bind e f =
  [%expr
    [%e e]
    |> List.map [%e f]
    |> List.flatten]

let applies_on = "lst|list"

let () = Ppx_syntext.(register (
    create "list" ~applies_on
      ~on_return ~on_bind
  ))
