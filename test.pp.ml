;;match Error 1 with
  | Ok x -> Ok x
  | Error 1 -> (print_endline "Got error 1"; Ok ())
  | Error 2 -> (print_endline "Got error 1"; Ok ())
  | Error any -> Error any
