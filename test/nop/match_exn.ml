let () =
  match%nop print_endline "match"; failwith "qjdswflk" with
  | None -> print_endline "none"
  | Some true -> print_endline "true"
  | exception Failure _ -> print_endline "failure"
  | Some false -> print_endline "false"

let () =
  match%nop print_endline "match"; failwith "qjdswflk" with
  | None -> print_endline "none"
  | exception Invalid_argument _ -> print_endline "invalid argument"
  | Some true -> print_endline "true"
  | exception Failure _ -> print_endline "failure"
  | Some false -> print_endline "false"

let () =
  match%nop print_endline "match"; failwith "qjdswflk" with
  | None -> print_endline "none"
  | exception _ -> print_endline "_"
  | Some true -> print_endline "true"
  | Some false -> print_endline "false"

let () =
  try
    match%nop print_endline "match"; failwith "qjdswflk" with
    | None -> print_endline "none"
    | exception Invalid_argument _ -> print_endline "invalid argument"
    | Some true -> print_endline "true"
    | Some false -> print_endline "false"
  with
    Failure _ -> print_endline "failure"
