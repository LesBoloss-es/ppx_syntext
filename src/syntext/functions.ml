open Migrate_parsetree
open OCaml_411.Ast
open Asttypes
open Ast_helper
open Parsetree

type on_assert =
  expression -> expression

type on_for =
  pattern -> expression -> expression ->
  direction_flag -> expression -> expression

type on_ifthenelse =
  expression -> expression -> expression option ->
  expression

type on_let =
  rec_flag -> value_binding list -> expression -> expression

type on_match = expression -> case list -> expression

type on_sequence = expression -> expression -> expression

type on_try = on_match

type on_while = on_sequence

type t = {
  on_assert     : on_assert ;
  on_for        : on_for ;
  on_ifthenelse : on_ifthenelse ;
  on_let        : on_let ;
  on_match      : on_match ;
  on_sequence   : on_sequence ;
  on_try        : on_try ;
  on_while      : on_while ;
}

let does_not_support ?(ppx_name="This PPX") ?requires construct =
  Location.raise_errorf "%s does not support %s%a"
    ppx_name construct
    (fun fmt -> function
       | None -> ()
       | Some requires ->
         Format.fprintf fmt "\n(requires %s)" requires)
    requires

(* =============================== [ Assert ] =============================== *)

(* FIXME: we can be smarter here and support assert_false with just
   on_return_error *)

let create_on_assert_from_monad ~on_return ~on_bind ~on_return_error () =
  (* assert%ext false
     =>
     try assert false
     with exn -> return_error exn *)

  (* assert%ext e
     =>
     bind e
       (function
        | true -> return ()
        | false ->
          try assert false
          with exn -> return_error exn) *)

  let assert_false =
    let pexn, eexn = Helpers.fresh_variable () in
    [%expr try assert false with [%p pexn] -> [%e on_return_error eexn]]
  in

  function
  | [%expr false] -> assert_false

  | e ->
    on_bind e Exp.(function_ [
        case [%pat? true] (on_return [%expr ()]);
        case [%pat? false] assert_false
      ])

let create_on_assert
    ?ppx_name
    ?on_assert ?on_assert_false
    ?on_return ?on_bind ?on_return_error
    ()
  =
  let on_assert =
    match on_assert with
    | Some on_assert -> on_assert
    | None ->
      match on_return, on_bind, on_return_error with
      | Some on_return, Some on_bind, Some on_return_error -> create_on_assert_from_monad ~on_return ~on_bind ~on_return_error ()
      | _ -> fun _ ->
        does_not_support ?ppx_name "assert"
          ~requires:"on_assert or on_return+on_bind+on_return_error"
  in
  fun e ->
  match e, on_assert_false with
  | [%expr false], Some on_assert_false -> on_assert_false ()
  | e, _ -> on_assert e

(* ================================ [ For ] ================================= *)

let create_on_for_from_monad ~on_return ~on_bind () =
  (* for%ext i = start dir stop do
       e
     done

     => (if dir = Up)

     let j0 = start in
     let jn = stop in
     let rec for_ j =
       if j > jn then
         return ()
       else
         bind
           (let i = j in e)
           (fun () -> for_ (j + 1))
     in
     for_ j0 *)

  fun i start stop dir e ->

  let pfor, for_  = Helpers.fresh_variable () in
  let pj,  j  = Helpers.fresh_variable () in
  let pj0, j0 = Helpers.fresh_variable () in
  let pjn, jn = Helpers.fresh_variable () in

  let j_gt_jn, j_plus_1 =
    match dir with
    | Upto -> [%expr [%e j] > [%e jn]], [%expr [%e j] + 1]
    | Downto -> [%expr [%e j] < [%e jn]], [%expr [%e j] - 1]
  in
  [%expr
    let [%p pj0] = [%e start] in
    let [%p pjn] = [%e stop] in
    let rec [%p pfor] = fun [%p pj] ->
      if [%e j_gt_jn] then
        [%e on_return [%expr ()]]
      else
        [%e on_bind [%expr let [%p i] = [%e j] in [%e e]]
            [%expr fun () -> [%e for_] [%e j_plus_1]]]
    in
    [%e for_] [%e j0]]

(* FIXME: on_simple_for = for i = 0 to n do ... done *)

let create_on_for
    ?ppx_name
    ?on_for ?on_return ?on_bind
    ()
  =
  match on_for with
  | Some on_for -> on_for
  | None ->
    match on_return, on_bind with
    | Some on_return, Some on_bind -> create_on_for_from_monad ~on_return ~on_bind ()
    | _ -> fun _ _ _ _ ->
      does_not_support ?ppx_name "for"
        ~requires:"on_for or on_return+on_bind"

(* ================================= [ If ] ================================= *)

(* FIXME: we can be a bit better here and and support the whole if is bind and
   simple_ifthen are given but not return or simple_ifthenelse *)

let create_on_ifthenelse_from_monad
    ?ppx_name
    ?on_return on_bind
  =
  (* if%ext e1 then e2             =>     bind e1 (function true -> e2 | false -> return ()) *)
  (* if%ext e1 then e2 else e3     =>     bind e1 (function true -> e2 | false -> e3) *)
  fun e1 e2 e3 ->
  match e3, on_return with
  | None, None ->
    does_not_support ?ppx_name "ifthen with no else"
      ~requires:"on_ifthenelse or on_simple_ifthen or on_return+on_bind"
  | None, Some on_return ->
    on_bind e1 Exp.(function_ [case [%pat? true] e2; case [%pat? false] (on_return [%expr ()])])
  | Some e3, _ ->
    on_bind e1 Exp.(function_ [case [%pat? true] e2; case [%pat? false] e3])

let create_on_ifthenelse_from_simple
    ?ppx_name
    ?on_simple_ifthen ?on_simple_ifthenelse
    ()
  =
  fun e1 e2 e3 ->
  match e3 with
  | None ->
    (
      match on_simple_ifthen with
      | Some on_simple_ifthen -> on_simple_ifthen e1 e2
      | None ->
        does_not_support ?ppx_name "ifthen with no else"
          ~requires:"on_ifthenelse or on_simple_ifthen or on_return+on_bind"
    )
  | Some e3 ->
    (
      match on_simple_ifthenelse with
      | Some on_simple_ifthenelse -> on_simple_ifthenelse e1 e2 e3
      | None ->
        does_not_support ?ppx_name "ifthenelse (with else)"
          ~requires:"on_ifthenelse or on_simple_ifthenelse or on_bind"
    )

let create_on_ifthenelse
    ?ppx_name
    ?on_ifthenelse
    ?on_simple_ifthen ?on_simple_ifthenelse
    ?on_return ?on_bind
    ()
  =
  match on_ifthenelse with
  | Some on_ifthenelse -> on_ifthenelse
  | None ->
    match on_simple_ifthen, on_simple_ifthenelse with
    | Some _, _ | _, Some _ ->
      create_on_ifthenelse_from_simple ?ppx_name ?on_simple_ifthen ?on_simple_ifthenelse ()
    | None, None ->
      match on_bind with
      | Some on_bind ->
        create_on_ifthenelse_from_monad ?ppx_name ?on_return on_bind
      | None -> fun _ _ _ ->
        does_not_support ?ppx_name "ifthenelse"
          ~requires:"on_ifthenelse or on_simple_ifthen+on_simple_ifthenelse or on_return+on_bind"

(* ================================ [ Let ] ================================= *)

let create_on_let_from_simple
    ?ppx_name
    ?on_and on_simple_let
  =

  let on_and () =
    match on_and with
    | Some on_and -> on_and
    | None ->
      does_not_support ?ppx_name "and"
        ~requires:"on_let or on_simple_let+on_and or on_return+on_bind"
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

    if rec_flag <> Nonrecursive then
      does_not_support ?ppx_name "recursive let"
        ~requires:"on_let";

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

let create_on_let_from_monad ?on_return on_bind =
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
          on_bind e1
            [%expr fun v1 ->
              [%e on_bind e2 [%expr fun v2 ->
                  [%e on_return [%expr (v1, v2)]]]]])
    | None -> None
  in
  create_on_let_from_simple ?on_and on_simple_let

let create_on_let
    ?ppx_name
    ?on_let
    ?on_simple_let ?on_and
    ?on_return ?on_bind
    ()
  =
  match on_let with
  | Some on_let -> on_let
  | None ->
    match on_simple_let with
    | Some on_simple_let ->
      create_on_let_from_simple ?ppx_name on_simple_let ?on_and
    | None ->
      match on_bind with
      | Some on_bind ->
        create_on_let_from_monad ?on_return on_bind
      | None -> fun _ _ _ ->
        does_not_support ?ppx_name "let"
          ~requires:"on_let or on_simple_let or on_bind"

(* =============================== [ Match ] ================================ *)

let create_on_match_from_simple ?ppx_name ~on_try on_simple_match =
  fun e cases ->

  (* match%ext e with
     | p1 -> e1
     | ...
     | pn -> en
     | exception p'1 -> e'1
     | ...
     | exception p'm -> e'm

     =>

     try%ext
       match%ext e with
       | p1 -> e1
       | ...
       | pn -> en
     with
     | p'1 -> e'1
     | ...
     | p'm -> e'm *)

  (* FIXME: this transformation is broken! exceptions thrown by expressions in
     the match cases would be caught by the try, which is not what we want. *)

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
         | _ ->
           does_not_support ?ppx_name "match with exception patterns"
             ~requires:"on_match or on_simple_match+on_try or on_bind+on_return_error+on_bind_error")
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

let create_on_match_from_monad ?ppx_name ~on_try on_bind =
  create_on_match_from_simple ?ppx_name ~on_try
    (fun e cases -> on_bind e (Exp.function_ cases))

let create_on_match
    ?ppx_name
    ?on_match
    ?on_simple_match ~on_try
    ?on_bind
    ()
  =
  match on_match with
  | Some on_match -> on_match
  | None ->
    match on_simple_match with
    | Some on_simple_match ->
      create_on_match_from_simple ?ppx_name on_simple_match ~on_try
    | None ->
      match on_bind with
      | Some on_bind ->
        create_on_match_from_monad ?ppx_name ~on_try on_bind
      | None -> fun _ _ ->
        does_not_support ?ppx_name "match"
          ~requires:"on_match or on_simple_match or on_bind"

(* ============================== [ Sequence ] ============================== *)

let create_on_sequence_from_monad on_bind =
  fun e1 e2 ->
  (* FIXME: this forces the first element of a sequence to be of type unit, but
     this is usually just a warning in OCaml. Maybe there is a way to do that? *)
  on_bind e1 [%expr fun () -> [%e e2]]

let create_on_sequence
    ?ppx_name
    ?on_sequence ?on_bind
    ()
  =
  match on_sequence with
  | Some on_sequence -> on_sequence
  | None ->
    match on_bind with
    | Some on_bind -> create_on_sequence_from_monad on_bind
    | None -> fun _ _ ->
      does_not_support ?ppx_name "sequence"
        ~requires:"on_sequence or on_bind"

(* ================================ [ Try ] ================================= *)

let create_on_try_from_monad_error ~on_return_error ~on_bind_error () =
  fun e cases ->
  let cases = Helpers.add_catchall_if_needed cases on_return_error in
  on_bind_error e (Exp.function_ cases)

let create_on_try
    ?ppx_name
    ?on_try
    ?on_return_error ?on_bind_error
    ()
  =
  match on_try with
  | Some on_try -> on_try
  | None ->
    match on_return_error, on_bind_error with
    | Some on_return_error, Some on_bind_error -> create_on_try_from_monad_error ~on_return_error ~on_bind_error ()
    | Some _, None | None, Some _ ->
      assert false
    | None, None -> fun _ _ ->
      does_not_support ?ppx_name "try"
        ~requires:"on_try or on_return_error+on_bind_error"

(* =============================== [ While ] ================================ *)

let create_on_while_from_monad
    ~on_return ~on_bind
    ()
  =

  (* while%ext e1 do
       e2
     done

     =>

     let while_ () =
       bind e1
         (function
          | true -> bind e2 while_
          | false -> return ()) *)

  fun e1 e2 ->

  let pwhile, ewhile = Helpers.fresh_variable () in

  [%expr
    let rec [%p pwhile] = fun () ->
      [%e on_bind e1 Exp.(function_ [
          case [%pat? true] (on_bind e2 ewhile) ;
          case [%pat? false] (on_return [%expr ()])
             ])]
    in [%e ewhile] ()]

let create_on_while
    ?ppx_name
    ?on_while
    ?on_return ?on_bind
    ()
  =
  match on_while with
  | Some on_while -> on_while
  | None ->
    match on_return, on_bind with
    | Some on_return, Some on_bind -> create_on_while_from_monad ~on_return ~on_bind ()
    | _ -> fun _ _ ->
      does_not_support ?ppx_name "while"
        ~requires:"on_while or on_return+on_bind"
