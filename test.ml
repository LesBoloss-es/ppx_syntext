try%res
  Error 1
with
| 1 -> print_endline "Got error 1"; Ok ()
| 2 -> print_endline "Got error 1"; Ok ()
;;

let foo =
  let%res e = assert%result (1 = 2) in
  let%res x = assert%result false in
  Ok ()
;;

match foo with
| Ok x -> print_endline "Got OK."
| Error x -> print_endline "Got error."; raise x
