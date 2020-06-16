let seq e1 e2 =
  match e1 () with
  | None -> None
  | Some () -> e2 ()

let let_ e1 e2 =
  match e1 () with
  | None -> None
  | Some v1 -> e2 v1

let and_ e1 e2 =
  match e1 () with
  | None -> None
  | Some v1 ->
    match e2 () with
    | None -> None
    | Some v2 -> Some (v1, v2)

let if_ e1 e2 e3 =
  match e1 () with
  | None -> None
  | Some true -> e2 ()
  | Some false -> e3 ()

let match_ e cases =
  match e () with
  | None -> None
  | Some v ->
    try
      cases v
    with
      Common.Exn exn -> raise exn

let try_ e cases =
  match e () with
  | None -> None
  | Some v -> Some v
  | exception exn -> match_ (fun () -> Some exn) cases

let assert_ e =
  try
    Some (assert (e ()))
  with
    Assert_failure _ -> None

let rec while_ e1 e2 =
  match e1 () with
  | None -> None
  | Some false -> Some ()
  | Some true ->
    match e2 () with
    | None -> None
    | Some () -> while_ e1 e2

let for_ e1 dir e2 e3 =
  let (+), (>) =
    match dir with
    | Common.Upto -> (+), (>)
    | Downto -> (-), (<)
  in
  (* FIXME: ordre d'évaluation dans le for ? *)
  let v1 = e1 () in
  let v2 = e2 () in
  let rec for_ i =
    if i > v2 then
      Some ()
    else
      match e3 () with
      | None -> None
      | Some () -> for_ (i + 1)
  in
  for_ v1
