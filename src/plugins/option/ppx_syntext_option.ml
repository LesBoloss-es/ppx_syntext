open Migrate_parsetree
open OCaml_411.Ast

let on_return x =
  [%expr Some [%e x]]

let on_bind o f =
  let px, x = Ppx_syntext.Helpers.fresh_variable () in
  [%expr
    match [%e o] with
    | Some [%p px] -> [%e f] [%e x]
    | None -> None]

let on_return_error x =
  [%expr
    ignore [%e x];
    None]

let on_bind_error o f =
  let px, x = Ppx_syntext.Helpers.fresh_variable () in
  [%expr
    match [%e o] with
    | Some [%p px] -> Some [%e x]
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
