open Migrate_parsetree
open OCaml_411.Ast
open Ast_helper
open Parsetree

let add_catchall_if_needed cases f =
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
    cases @ [Exp.case [%pat? any] (f [%expr any])]
