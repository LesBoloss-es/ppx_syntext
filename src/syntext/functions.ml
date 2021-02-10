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

(* FIXME: replace all the assert by proper error reporting *)

(* ============================== [ Sequence ] ============================== *)

let create_on_sequence_from_bind on_bind =
  fun e1 e2 ->
  (* FIXME: this forces the first element of a sequence to be of type unit, but
     this is usually just a warning in OCaml. Maybe there is a way to do that? *)
  on_bind e1 [%expr fun () -> [%e e2]]

let create_on_sequence ?on_sequence ?on_bind () =
  match on_sequence with
  | Some on_sequence -> on_sequence
  | None ->
    match on_bind with
    | Some on_bind -> create_on_sequence_from_bind on_bind
    | None -> fun _ _ -> assert false

(* ================================ [ Let ] ================================= *)

let create_on_let_from_simple ?on_and on_simple_let =
  let on_and () =
    match on_and with
    | Some on_and -> on_and
    | None -> assert false
  in
  fun rec_flag vbs e ->

  (* let x1 = e1
     and x2 = e2
     ...
     and xn = en
     in
     e

     =>

     let (...(x1, x2), ... xn) = (...(e1, e2), ... en) in e

     except we do not build (...(e1, e2), ... en) ourselves but we ask on_and, so:

     let (...(x1, x2), ... xn) = (on_and ... (on_and e1 e2) en) in e
  *)

  assert (rec_flag = Nonrecursive);
  let ands =
    List.fold_left
      (fun ands vb -> on_and () ands vb.pvb_expr)
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

let create_on_let_from_bind ?on_return on_bind =
  (* We can easily create a simple let and a and from bind and return.

     let x = e1 in e2     =>     bind e1 (fun x -> e2)

     on_and e1 e2         =>     bind e1 (fun v1 -> bind e2 (fun v2 -> return (v1, v2)))
  *)

  let on_simple_let x e1 e2 = on_bind e1 [%expr fun [%p x] -> [%e e2]] in
  (* FIXME: in on_and, use "unique" variables *)
  let on_and =
    (* With just bind, we can create the simple let. However, return is required
       to build the and. *)
    match on_return with
    | Some on_return ->
      Some (fun e1 e2 ->
          on_bind e1 [%expr fun v1 -> [%e on_bind e2 [%expr fun v2 -> [%e on_return [%expr (v1, v2)]]]]])
    | None -> None
  in
  create_on_let_from_simple ?on_and on_simple_let

let create_on_let ?on_let ?on_simple_let ?on_and ?on_return ?on_bind () =
  match on_let with
  | Some on_let -> on_let
  | None ->
    match on_simple_let with
    | Some on_simple_let -> create_on_let_from_simple on_simple_let ?on_and
    | None ->
      match on_bind with
      | Some on_bind -> create_on_let_from_bind ?on_return on_bind
      | None -> fun _ _ _ -> assert false

(* =============================== [ Match ] ================================ *)

let create_on_match_from_simple ~on_try on_simple_match =
  fun e cases ->

  (* match%ext e with
     | ... -> ...
     | exception E -> ...
     | exception F -> ...

     =>

     try%ext
       match%ext e with
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
    on_try match_ exns

let create_on_match_from_bind ~on_try on_bind =
  create_on_match_from_simple ~on_try (fun e cases -> on_bind e (Exp.function_ cases))

let create_on_match ?on_match ?on_simple_match ~on_try ?on_bind () =
  match on_match with
  | Some on_match -> on_match
  | None ->
    match on_simple_match with
    | Some on_simple_match -> create_on_match_from_simple on_simple_match ~on_try
    | None ->
      match on_bind with
      | Some on_bind -> create_on_match_from_bind ~on_try on_bind
      | None -> fun _ _ -> assert false

(* ================================ [ Try ] ================================= *)

let create_on_try_from_bind_error ~on_return_error ~on_bind_error () =
  fun e cases ->
  let cases = Helpers.add_catchall_if_needed cases on_return_error in
  on_bind_error e (Exp.function_ cases)

let create_on_try ?on_try ?on_return_error ?on_bind_error () =
  match on_try with
  | Some on_try -> on_try
  | None ->
    match on_return_error, on_bind_error with
    | Some on_return_error, Some on_bind_error -> create_on_try_from_bind_error ~on_return_error ~on_bind_error ()
    | Some _, None | None, Some _ -> assert false
    | None, None -> fun _ _ -> assert false

(* ================================= [ If ] ================================= *)

let create_on_ifthenelse_from_bind ?on_return on_bind =
  (* if%ext e1 then e2             =>     e1 >>= function true -> e2 | false -> return () *)
  (* if%ext e1 then e2 else e3     =>     e1 >>= function true -> e2 | false -> e3 *)
  fun e1 e2 e3 ->
  match e3, on_return with
  | None, None -> assert false
  | None, Some on_return -> on_bind e1 Exp.(function_ [case [%pat? true] e2; case [%pat? false] (on_return [%expr ()])])
  | Some e3, _           -> on_bind e1 Exp.(function_ [case [%pat? true] e2; case [%pat? false] e3])

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

let create_on_ifthenelse ?on_ifthenelse ?on_simple_ifthen ?on_simple_ifthenelse ?on_return ?on_bind () =
  match on_ifthenelse with
  | Some on_ifthenelse -> on_ifthenelse
  | None ->
    match on_simple_ifthen, on_simple_ifthenelse with
    | Some _, _ | _, Some _ -> create_on_ifthenelse_from_simple ?on_simple_ifthen ?on_simple_ifthenelse ()
    | None, None ->
      match on_bind with
      | Some on_bind -> create_on_ifthenelse_from_bind ?on_return on_bind
      | None -> fun _ _ _ -> assert false

(* =============================== [ While ] ================================ *)

let create_on_while_from_bind ~on_return ~on_bind () =
  (* while%ext e1 do e2 done

     =>

     let while_ () =
       e1 >>= function
       | true -> e2 >>= while_
       | false -> return ()      *)

  fun e1 e2 ->

  [%expr let rec while_ () =
           [%e on_bind e1 Exp.(function_ [
               case [%pat? true] (on_bind e2 [%expr while_]) ;
               case [%pat? false] (on_return [%expr ()])
             ])]
    in while_ ()]

let create_on_while ?on_while ?on_return ?on_bind () =
  match on_while with
  | Some on_while -> on_while
  | None ->
    match on_return, on_bind with
    | Some on_return, Some on_bind -> create_on_while_from_bind ~on_return ~on_bind ()
    | _ -> fun _ _ -> assert false

(* ================================ [ For ] ================================= *)

let create_on_for_from_bind ~on_return ~on_bind () =
  (* for%ext i = start dir stop; do e done

     => (if dir = Up)

     let rec for_ j =
       if j > stop then
         return ()
       else
         (let i = j in e) >>= fun () -> for_ (j + 1)   *)

  fun i start stop dir e ->
  let j_gt_stop, j_plus_1 =
    match dir with
    | Upto -> [%expr j > [%e stop]], [%expr j + 1]
    | Downto -> [%expr j < [%e stop]], [%expr j - 1]
  in
  [%expr let rec for_ j =
           if [%e j_gt_stop] then
             [%e on_return [%expr ()]]
           else
             [%e on_bind [%expr let [%p i] = j in [%e e]]
                 [%expr fun () -> for_ [%e j_plus_1]]]
    in
    for_ [%e start]]

(* FIXME: on_simple_for = for i = 0 to n do ... done *)

let create_on_for ?on_for ?on_return ?on_bind () =
  match on_for with
  | Some on_for -> on_for
  | None ->
    match on_return, on_bind with
    | Some on_return, Some on_bind -> create_on_for_from_bind ~on_return ~on_bind ()
    | _ -> fun _ _ _ _ -> assert false

(* =============================== [ Assert ] =============================== *)

let create_on_assert_from_bind ~on_return ~on_bind ~on_return_error () =
  (* assert%ext e     =>     e >>= function true -> return () | false -> return "assert false" *)

  fun e ->

  on_bind e Exp.(function_ [
      case [%pat? true] (on_return [%expr ()]);
      case [%pat? false] [%expr try assert false with exn -> [%e on_return_error [%expr exn]]]
    ])

let create_on_assert ?on_assert ?on_assert_false ?on_return ?on_bind ?on_return_error () =
  let on_assert =
    match on_assert with
    | Some on_assert -> on_assert
    | None ->
      match on_return, on_bind, on_return_error with
      | Some on_return, Some on_bind, Some on_return_error -> create_on_assert_from_bind ~on_return ~on_bind ~on_return_error ()
      | _ -> fun _ -> assert false
  in
  fun e ->
  match e, on_assert_false with
  | [%expr false], Some on_assert_false -> on_assert_false ()
  | e, _ -> on_assert e
