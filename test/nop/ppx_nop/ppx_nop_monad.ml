open Migrate_parsetree
open OCaml_411.Ast

let on_bind e f =
  [%expr [%e f] [%e e]]

let on_return e =
  e

let on_bind_error e f =
  let pexn, exn = Ppx_syntext.Helpers.fresh_variable () in
  [%expr
    try
      [%e e]
    with
    | [%p pexn] -> [%e f] [%e exn]]

let on_return_error e =
  [%expr raise [%e e]]

let () = Ppx_syntext.(register (
    create "ppx_nop_monad"
      ~applies_on:"nop"
      ~on_bind ~on_return
      ~on_bind_error ~on_return_error
  ))
