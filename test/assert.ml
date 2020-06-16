let () =
  try
    assert%nop (print_endline "assert"; true)
  with
    Assert_failure _ -> print_endline "assert failure"

let () =
  try
    assert%nop (print_endline "assert"; false)
  with
    Assert_failure _ -> print_endline "assert failure"
