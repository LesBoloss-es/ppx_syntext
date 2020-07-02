open Arg
let bad_arg fmt = Format.kasprintf (fun s -> raise (Arg.Bad s)) fmt

let list_find ~if_ l =
  let rec list_find = function
    | [] -> None
    | e :: _ when if_ e -> Some e
    | _ :: l -> list_find l
  in
  list_find l

let list_update ~if_ ~update ~add l =
  let rec list_update acc = function
    | [] -> List.rev_append acc [add ()]
    | e :: l when if_ e -> List.rev_append acc (update e :: l)
    | e :: l -> list_update (e :: acc) l
  in
  list_update [] l

type extension =
  { key : string ;
    module_ : Longident.t option }

type t = { extensions : extension list }

let default = { extensions = [] }

let add_extension key config =
  let extensions =
    list_update
      ~if_:(fun ext -> ext.key = key)
      ~update:(fun _ -> bad_arg "extension '%s' already exists" key)
      ~add:(fun () -> { key; module_ = None })
      config.extensions
  in
  { extensions }

let extension_exists key config =
  match list_find ~if_:(fun ext -> ext.key = key) config.extensions with
  | None -> false
  | Some _ -> true

let set_module_for key module_ config =
  let extensions =
    list_update
      ~if_:(fun ext -> ext.key = key )
      ~update:(fun ext ->
          match ext.module_ with
          | Some _ -> bad_arg "cannot set module for '%s': " key
          | None -> { key; module_ = Some module_ })
      ~add:(fun _ -> bad_arg "cannot set module for '%s': extension does not exist" key)
      config.extensions
  in
  { extensions }

let get_module_for key config =
  match list_find ~if_:(fun ext -> ext.key = key) config.extensions with
  | None -> bad_arg "cannot get module for '%s': extension does not exist" key
  | Some ext -> ext.module_

module State = struct
  let current = ref { extensions = [] }

  let last_key = ref ""

  let add_extension key =
    current := add_extension key !current;
    last_key := key

  let extension_exists key =
    extension_exists key !current

  let set_module_for_last module_ =
    let module_ =
      match Longident.unflatten (String.split_on_char '.' module_) with
      | None -> bad_arg "could not understand '%s' as a module" module_
      | Some module_ -> module_
    in
    current := set_module_for !last_key module_ !current

  let get_module_for key =
    get_module_for key !current

  let args = [
    "--extension", String add_extension, "NAME adds the extension NAME";
    "-e",          String add_extension, "NAME short for --extension";

    "--module", String set_module_for_last, "STRING sets the module for last extension";
    "-m",       String set_module_for_last, "STRING short for --module";
  ]
end
