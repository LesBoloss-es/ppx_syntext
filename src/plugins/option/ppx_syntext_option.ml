open Migrate_parsetree
open OCaml_411.Ast

let on_return x =
  [%expr Some [%e x]]

let on_bind o f =
  [%expr
    match [%e o] with
    | Some syntext_var_x -> [%e f] syntext_var_x
    | None -> None]

let on_return_error x =
  [%expr
    ignore [%e x];
    None]

let on_bind_error o f =
  [%expr
    match [%e o] with
    | Some syntext_var_x -> Some syntext_var_x
    | None -> [%e f] ()]

let on_assert_false () =
  [%expr None]

let on_assert e =
  [%expr
    if [%e e] then
      Some ()
    else
      None]

let applies_on = "opt(ion)?"

let () = Ppx_syntext.(register (
    create "option" ~applies_on
      ~on_return ~on_bind
      ~on_return_error ~on_bind_error
      ~on_assert ~on_assert_false
  ))
