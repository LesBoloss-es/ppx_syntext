open Migrate_parsetree
open OCaml_411.Ast

let on_return x = [%expr Ok [%e x]]

let on_bind r f = [%expr match [%e r] with Ok x -> [%e f] x | Error e -> Error e]

let on_return_error e = [%expr Error [%e e]]

let on_bind_error r f = [%expr match [%e r] with Ok x -> Ok x | Error e -> [%e f] e]

let on_assert_false () = [%expr try assert false with exn -> Error exn]

let on_assert e = [%expr if [%e e] then Ok () else [%e on_assert_false ()]]

let () = Ppx_syntext.(register (
    create "result.ok" ~applies_on:"ok|res(ult)?(.ok)?"
      ~on_return ~on_bind
      ~on_return_error ~on_bind_error
      ~on_assert ~on_assert_false
  ))

let () = Ppx_syntext.(register (
    create "result.error" ~applies_on:"(res(ult)?.)?err(or)?"
      ~on_return:on_return_error ~on_bind:on_bind_error
  ))
