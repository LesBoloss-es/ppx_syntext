(* module SyntextConfig = Config
 * open Migrate_parsetree
 * open OCaml_411.Ast
 * open Ast_mapper
 * open Ast_helper
 * open Asttypes
 * open Parsetree
 *
 * (\** The Syntext Mapper *\)
 *
 * type t = {
 * } *)











(* let function_name config ~ext ?(reserved=true) name =
 *   let ident =
 *     match SyntextConfig.get_module_for ext config with
 *     | None -> Longident.Lident ("syntext_" ^ ext ^ "_" ^ name)
 *     | Some module_ -> Longident.Ldot (module_, name ^ (if reserved then "_" else ""))
 *   in
 *   Exp.ident (Location.mkloc ident !default_loc)
 *
 * let thunk ?(p=[%pat? ()]) e = [%expr fun [%p p] -> [%e e]]
 *
 * let direction_expr = function
 *   | Upto -> [%expr Syntext.Upto]
 *   | Downto -> [%expr Syntext.Downto]
 *
 *
 * let match_of_simple simple_match try_ e cases =
 *   (\* match e with
 *      | ... -> ...
 *      | exception E -> ...
 *      | exception F -> ...
 *
 *      =>
 *
 *      try
 *        match e with
 *        | ... -> ...
 *      with
 *      | E -> ...
 *      | F -> ... *\)
 *
 *     let (cases, exns) =
 *       List.partition
 *         (fun case ->
 *            match case.pc_lhs.ppat_desc with
 *            | Ppat_exception _ -> false
 *            | _ -> true)
 *         cases
 *     in
 *     let exns =
 *       List.map
 *         (fun case ->
 *            match case.pc_lhs.ppat_desc with
 *            | Ppat_exception pat -> { case with pc_lhs = pat }
 *            | _ -> assert false)
 *         exns
 *     in
 *     let match_ =
 *       [%expr [%e function_name conf ~ext "match"] [%e thunk e] [%e Exp.function_ cases]]
 *     in
 *     (\* We could always use the second case and wrap the match in a useless try.
 *        That is a bit slower in term of performances. More importantly, it means
 *        that even for the use of simple match constructs without exceptions, one
 *        would have to define [syntext_*_try], and we want to avoid that. *\)
 *     if exns = [] then
 *       match_
 *     else
 *       [%expr [%e function_name conf ~ext "try"]
 *           (fun () -> [%e match_])
 *           [%e Exp.function_ (add_catchall exns)]]
 *
 * let if_of_simple if_then if_then_else e1 e2 = function
 *   | None -> if_then e1 e2
 *   | Some e3 -> if_then_else e1 e2 e3
 *
 * let assert_of_simple simple_assert assert_false = function
 *   | [%expr false] -> assert_false
 *   | e -> simple_assert e
 *
 * let apply_ext_to_expr ext = function
 *   | Pexp_sequence (e1, e2) -> ext.on_sequence e1 e2
 *   | Pexp_let (rf, vbs, e) -> ext.on_let rf vbs e
 *   | Pexp_match (e, cases) -> ext.on_match e cases
 *   | Pexp_try (e, cases) -> ext.on_try e cases
 *   | Pexp_ifthenelse (e1, e2, e3) -> ext.on_if e1 e2 e3
 *   | Pexp_assert e -> ext.on_assert
 *   | Pexp_while (e1, e2) -> ext.on_while e1 e2
 *   | Pexp_for (i, e1, e2, dir, e3) -> ext.on_for i e1 e2 dir e3
 *   | _ -> expr
*)

(* let expr ext mapper = function
 *   | { pexp_desc =
 *         Pexp_extension (
 *           {txt; loc},
 *           PStr [ {pstr_desc = Pstr_eval (expr, _); _} ]
 *         );
 *       _ }
 *     when (txt = ext.name)
 *     ->
 *     ignore loc;
 *     let expr =
 *       match expr.pexp_desc with
 *       | Pexp_sequence (e1, e2) -> ext.on_sequence e1 e2
 *       | Pexp_let (rf, vbs, e) -> ext.on_let rf vbs e
 *       | Pexp_match (e, cases) -> ext.on_match e cases
 *       | Pexp_try (e, cases) -> ext.on_try e cases
 *       | Pexp_ifthenelse (e1, e2, e3) -> ext.on_ifthenelse e1 e2 e3
 *       | Pexp_assert e -> ext.on_assert
 *       | Pexp_while (e1, e2) -> ext.on_while e1 e2
 *       | Pexp_for (i, e1, e2, dir, e3) -> ext.on_for i e1 e2 dir e3
 *       | _ -> expr
 *     in
 *     default_mapper.expr mapper expr
 *
 *   | expr -> default_mapper.expr mapper expr
 *
 * let mapper config = { default_mapper with expr = expr config } *)
