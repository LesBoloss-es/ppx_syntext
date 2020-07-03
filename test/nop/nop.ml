(* This library defines a dummy extension that gives the same semantics as no
   extension at all. It is used for testing purposes: one can compare the output
   of a code using ppx_syntext on this extension and a code where the extension
   is ignored.*)

let seq e1 e2 =
  e1 (); e2 ()

let let_ e1 e2 =
  e2 (e1 ())

let and_ e1 e2 =
  (* Careful with evaluation order in pairs. *)
  let v1 = e1 () in
  (v1, e2 ())

let if_then e1 e2 =
  if e1 () then e2 ()

let if_then_else e1 e2 e3 =
  if e1 () then e2 () else e3 ()

let match_ e cases =
  try
    cases (e ())
  with
    Syntext.Exn exn -> raise exn

let try_ e cases =
  try
    e ()
  with
    exn ->
    match_ (fun () -> exn) cases

let assert_ e =
  assert (e ())

let assert_false () =
  assert false

let while_ e1 e2 =
  while e1 () do
    e2 ()
  done

let for_ e1 dir e2 e3 =
  match dir with
  | Syntext.Upto ->
    for i = e1 () to e2 () do
      e3 i
    done
  | Syntext.Downto ->
    for i = e1 () downto e2 () do
      e3 i
    done
