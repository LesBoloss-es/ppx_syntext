open Migrate_parsetree
open OCaml_411.Ast

let () = Ppx_syntext.(register (
    create "ppx_nop_monad"
      ~applies_on:"nop"
      ~on_bind:(fun e f -> [%expr [%e f] [%e e]])
      ~on_return:(fun e -> e)
  ))
