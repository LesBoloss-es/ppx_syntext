open Migrate_parsetree
open OCaml_411.Ast
open Asttypes
open Ast_helper
open Parsetree

type t = {
  on_let        : rec_flag -> value_binding list -> expression -> expression ;
  on_match      : expression -> case list -> expression ;
  on_try        : expression -> case list -> expression ;
  on_ifthenelse : expression -> expression -> expression option -> expression ;
  on_sequence   : expression -> expression -> expression ;
  on_while      : expression -> expression -> expression ;
  on_for        : pattern -> expression -> expression -> direction_flag -> expression -> expression ;
  on_assert     : expression -> expression ;
}

(* ============================== [ Sequence ] ============================== *)

let create_on_sequence ?on_sequence () =
  match on_sequence with
  | Some on_sequence -> on_sequence
  | None -> fun _ _ -> assert false (* FIXME: bind *)

(* ================================ [ Let ] ================================= *)

let create_on_let_from_simple ?on_and on_simple_let =
  let on_and () =
    match on_and with
    | Some on_and -> on_and
    | None -> assert false
  in
  fun rec_flag vbs e ->
  assert (rec_flag = Nonrecursive);
  let ands =
    List.fold_left
      (fun ands vb -> on_and () ands vb)
      (List.hd vbs).pvb_expr
      (List.tl vbs)
  in
  let pats =
    List.fold_left
      (fun pats vb -> Pat.tuple [pats; vb.pvb_pat])
      (List.hd vbs).pvb_pat
      (List.tl vbs)
  in
  on_simple_let pats ands e

let create_on_let ?on_let ?on_simple_let ?on_and () =
  match on_let with
  | Some on_let -> on_let
  | None ->
    match on_simple_let with
    | Some on_simple_let -> create_on_let_from_simple on_simple_let ?on_and
    | None -> fun _ _ _ -> assert false (* FIXME: bind *)

(* =============================== [ Match ] ================================ *)

let create_on_match_from_simple ?on_try on_simple_match =
  fun e cases ->

  (* match e with
     | ... -> ...
     | exception E -> ...
     | exception F -> ...

     =>

     try
       match e with
       | ... -> ...
     with
     | E -> ...
     | F -> ... *)

  let (cases, exns) =
    List.partition
      (fun case ->
         match case.pc_lhs.ppat_desc with
         | Ppat_exception _ -> false
         | _ -> true)
      cases
  in
  let exns =
    List.map
      (fun case ->
         match case.pc_lhs.ppat_desc with
         | Ppat_exception pat -> { case with pc_lhs = pat }
         | _ -> assert false)
      exns
  in
  let match_ = on_simple_match e cases in
  (* We could always use the second case and wrap the match in a useless try.
     That is a bit slower in term of performances. More importantly, it means
     that even for the use of simple match constructs without exceptions, one
     would have to define [on_try] which we want to avoid. *)
  if exns = [] then
    match_
  else
    match on_try with
    | Some on_try -> on_try match_ exns
    | None -> assert false

let create_on_match ?on_match ?on_simple_match ?on_try () =
  match on_match with
  | Some on_match -> on_match
  | None ->
    match on_simple_match with
    | Some on_simple_match -> create_on_match_from_simple on_simple_match ?on_try
    | None -> fun _ _ -> assert false

(* ================================ [ Try ] ================================= *)

let create_on_try ?on_try () =
  match on_try with
  | Some on_try -> on_try
  | None -> fun _ _ -> assert false

(* ================================= [ If ] ================================= *)

let create_on_ifthenelse_from_simple ?on_simple_ifthen ?on_simple_ifthenelse () =
  fun e1 e2 e3 ->
  match e3 with
  | None ->
    (match on_simple_ifthen with
     | Some on_simple_ifthen -> on_simple_ifthen e1 e2
     | None -> assert false)
  | Some e3 ->
    (match on_simple_ifthenelse with
     | Some on_simple_ifthenelse -> on_simple_ifthenelse e1 e2 e3
     | None -> assert false)

let create_on_ifthenelse ?on_ifthenelse ?on_simple_ifthen ?on_simple_ifthenelse () =
  match on_ifthenelse with
  | Some on_ifthenelse -> on_ifthenelse
  | None ->
    match on_simple_ifthen, on_simple_ifthenelse with
    | Some _, _ | _, Some _ -> create_on_ifthenelse_from_simple ?on_simple_ifthen ?on_simple_ifthenelse ()
    | None, None -> fun _ _ _ -> assert false

(* =============================== [ While ] ================================ *)

let create_on_while ?on_while () =
  match on_while with
  | Some on_while -> on_while
  | None -> fun _ _ -> assert false

(* ================================ [ For ] ================================= *)

let create_on_for ?on_for () =
  match on_for with
  | Some on_for -> on_for
  | None -> fun _ _ _ _ -> assert false

(* =============================== [ Assert ] =============================== *)

let create_on_assert ?on_assert ?on_assert_false () =
  function
  | [%expr false] ->
    (match on_assert_false, on_assert with
     | Some on_assert_false, _ -> on_assert_false ()
     | None, Some on_assert -> on_assert [%expr false]
     | None, None -> assert false)
  | e ->
    (match on_assert with
     | Some on_assert -> on_assert e
     | None -> assert false)
