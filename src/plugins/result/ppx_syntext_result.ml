open Migrate_parsetree
open OCaml_411.Ast

let on_return x =
  [%expr Ok [%e x]]

let on_bind r f =
  [%expr
    match [%e r] with
    | Ok syntext_var_x -> [%e f] x
    | Error syntext_var_e -> Error syntext_var_e]

let on_return_error e =
  [%expr Error [%e e]]

let on_bind_error r f =
  [%expr
    match [%e r] with
    | Ok syntext_var_x -> Ok syntext_var_x
    | Error syntext_var_e -> [%e f] syntext_var_e]

let on_assert_false () =
  (* It is not necessary to sanitise the variable here, but we do it for
     consistency. Better safe than sorry. *)
  [%expr
    try
      assert false
    with
    | syntext_var_exn -> Error syntext_var_exn]

let on_assert e =
  [%expr
    if [%e e] then
      Ok ()
    else [%e on_assert_false ()]]

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
