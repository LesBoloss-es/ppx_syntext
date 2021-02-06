;;match Error 1 with
  | Ok x -> Ok x
  | Error 1 -> (print_endline "Got error 1"; Ok ())
  | Error 2 -> (print_endline "Got error 1"; Ok ())
  | Error any -> Error any
let foo =
  match if 1 = 2 then Ok () else (try assert false with | exn -> Error exn)
  with
  | Ok x ->
      ((fun e ->
          match try assert false with | exn -> Error exn with
          | Ok x -> ((fun x -> Ok ())) x
          | Error e -> Error e)) x
  | Error e -> Error e
;;match foo with
  | Ok x -> print_endline "Got OK."
  | Error x -> (print_endline "Got error."; raise x)
