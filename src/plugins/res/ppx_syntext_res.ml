open Migrate_parsetree
open OCaml_411.Ast
(* open Ast_mapper *)
open Ast_helper
open Parsetree

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

let () = Ppx_syntext.(register (create "res" ~on_try))
