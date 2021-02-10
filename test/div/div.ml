let div x y =
  match x, y with
  | _, Ok 0 -> assert false
  | Ok x, Ok y -> Ok (x / y)
  | Error e, _ | _, Error e -> Error e

let div_let x y =
  let%ok x = x in
  let%ok y = y in
  assert%ok (y <> 0);%ok
  Ok (x / y)

let div_match x y =
  match%res y with
  | 0 -> assert%res false
  | y -> let%res x = x in Ok (x / y)

let map f = function
  | Ok x -> Ok (f x)
  | Error e -> Error e

let div_ifthen x y =
  if%res.ok map ((=) 0) y then
    assert%res.ok false;%res.ok
  let%res.ok x = x in Ok (x / y)

let div_ifthenelse x y =
  if%result.ok map ((=) 0) y then
    assert%result.ok false
  else
    let%result.ok x = x in
    Ok (x / y)
