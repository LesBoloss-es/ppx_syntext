open Migrate_parsetree
open OCaml_411.Ast
open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree

let function_name ~ext ?(reserved=true) name =
  let ident =
    match Syntext.Config.State.get_module_for ext with
    | None -> Longident.Lident ("syntext_" ^ ext ^ "_" ^ name)
    | Some module_ -> Longident.Ldot (module_, name ^ (if reserved then "_" else ""))
  in
  Exp.ident (Location.mkloc ident !default_loc)

let thunk ?(p=[%pat? ()]) e = [%expr fun [%p p] -> [%e e]]

let direction_expr = function
  | Upto -> [%expr Syntext.Upto]
  | Downto -> [%expr Syntext.Downto]

let add_catchall cases =
  let is_catchall case =
    let rec is_pat_catchall pat =
      match pat.ppat_desc with
      | Ppat_any | Ppat_var _ -> true
      | Ppat_alias (pat, _) | Ppat_constraint (pat,_) -> is_pat_catchall pat
      | _ -> false
    in
    case.pc_guard = None
    && is_pat_catchall case.pc_lhs
  in
  if List.exists is_catchall cases then
    cases
  else
    cases @ [Exp.case [%pat? exn] [%expr raise (Syntext.Exn exn)]]

let syntext_expr ~ext expr =
  match expr.pexp_desc with

  | Pexp_sequence (e1, e2) ->
    (* e1; e2
       => syntext_*_seq (fun () -> e1) (fun () -> e2) *)
    [%expr [%e function_name ~ext "seq" ~reserved:false] [%e thunk e1] [%e thunk e2]]

  | Pexp_let (Nonrecursive, vbs, e) ->
    (* let v1 = e1 in e
       => syntext_*_let (fun () -> e1) (fun v1 -> e) *)
    (* let v1 = e1 and v2 = e2 in e
       => syntext_*_let (fun () -> syntext_*_and (fun () -> e1) (fun () -> e2)) (fun (v1, v2) -> e) *)
    let ands =
      List.fold_left
        (fun ands vb ->
           [%expr [%e function_name ~ext "and"] [%e thunk ands] [%e thunk vb.pvb_expr]])
        (List.hd vbs).pvb_expr
        (List.tl vbs)
    in
    let pats =
      List.fold_left
        (fun pats vb -> Pat.tuple [pats; vb.pvb_pat])
        (List.hd vbs).pvb_pat
        (List.tl vbs)
    in
    [%expr [%e function_name ~ext "let"] [%e thunk ands] [%e thunk ~p:pats e]]

  | Pexp_match (e, cases) ->
    (* match e with cases
       => syntext_*_match (fun () -> e) (function cases) *)
    (* match e with cases | exns
       => try match e with cases with exns *)
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
    let match_ =
      [%expr [%e function_name ~ext "match"] [%e thunk e] [%e Exp.function_ cases]]
    in
    (* We could always use the second case and wrap the match in a useless try.
       That is a bit slower in term of performances. More importantly, it means
       that even for the use of simple match constructs without exceptions, one
       would have to define [syntext_*_try], and we want to avoid that. *)
    if exns = [] then
      match_
    else
      [%expr [%e function_name ~ext "try"]
          (fun () -> [%e match_])
          [%e Exp.function_ (add_catchall exns)]]

  | Pexp_try (e, cases) ->
    (* try e with cases
       => syntext_*_try (fun () -> e) (function cases) *)
    [%expr [%e function_name ~ext "try"] [%e thunk e] [%e Exp.function_ (add_catchall cases)]]

  | Pexp_ifthenelse (e1, e2, e3) ->
    (* if e1 then e2
       => syntext_*_if (fun () -> e1) (fun () -> e2) None *)
    (* if e1 then e2 else e3
       => syntext_*_if (fun () -> e1) (fun () -> e2) (Some (fun () -> e3)) *)
    let e3 =
      match e3 with
      | None -> [%expr None]
      | Some e3 -> [%expr Some [%e thunk e3]]
    in
    [%expr [%e function_name ~ext "if"] [%e thunk e1] [%e thunk e2] [%e e3]]

  | Pexp_assert [%expr false] ->
    [%expr [%e function_name ~ext "assert_false" ~reserved:false] ()]

  | Pexp_assert e ->
    [%expr [%e function_name ~ext "assert"] [%e thunk e]]

  | Pexp_while (e1, e2) ->
    [%expr [%e function_name ~ext "while"] [%e thunk e1] [%e thunk e2]]

  | Pexp_for (i, e1, e2, dir, e3) ->
    [%expr [%e function_name ~ext "for"] [%e thunk e1] [%e direction_expr dir] [%e thunk e2] [%e thunk ~p:i e3]]

  | _ -> expr

let expr mapper = function
  | { pexp_desc =
        Pexp_extension (
          {txt; loc},
          PStr [ {pstr_desc = Pstr_eval (expr, _); _} ]
        );
      _ }
    when Syntext.Config.State.extension_exists txt
    ->
    ignore loc;
    let expr = syntext_expr ~ext:txt expr in
    default_mapper.expr mapper expr

  | expr -> default_mapper.expr mapper expr

let mapper = { default_mapper with expr }

let () =
  Driver.register ~name:"ppx_syntext" ~args:Syntext.Config.State.args Versions.ocaml_411
    (fun _config _cookies -> mapper)
