open Migrate_parsetree
open OCaml_411.Ast
open Ast_helper
open Parsetree

(* ================================= [ Ok ] ================================= *)

let on_return x = [%expr Ok [%e x]]

let on_bind r f = [%expr match [%e r] with Ok x -> [%e f] x | Error e -> Error e]

let on_try e cases =
  (* try e with cases

     =>

     match e with
     | Ok x -> Ok x
     | Error e -> match e with cases *)

  (* Add a catchall for errors if there is none. It simply returns an error
     immediately. *)
  let cases =
    Ppx_syntext.Helpers.add_catchall_if_needed
      cases (fun v -> [%expr Error [%e v]])
  in

  (* Lift all the patterns p to Error p. *)
  let cases =
    List.map (fun case ->
        { case with pc_lhs = [%pat? Error [%p case.pc_lhs]]})
      cases
  in

  (* Add a case for Ok which simply returns the same value. *)
  let cases =
    (Exp.case [%pat? Ok x] [%expr Ok x]) :: cases
  in

  (* Return a match construct. *)
  Exp.(match_ e cases)

let on_assert_false () = [%expr try assert false with exn -> Error exn]
let on_assert e = [%expr if [%e e] then Ok () else [%e on_assert_false ()]]

let applies_on = "ok|res(ult)?(.ok)?"

let () = Ppx_syntext.(register (create "result.ok" ~applies_on
           ~on_return ~on_bind ~on_try ~on_assert ~on_assert_false))

(* =============================== [ Error ] ================================ *)

let on_return e = [%expr Error [%e e]]

let on_bind r f = [%expr match [%e r] with Ok x -> Ok x | Error e -> [%e f] e]

let applies_on = "(res(ult)?.)?err(or)?"

let () = Ppx_syntext.(register (create "result.error" ~applies_on
                                  ~on_return ~on_bind))
