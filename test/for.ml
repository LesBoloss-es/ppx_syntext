let () =
  for%nop i = (print_endline "1"; 1) to (print_endline "3"; 3) do
    print_string "for "; print_int i; print_newline ()
  done

let () =
  for%nop i = (print_endline "1"; 1) downto (print_endline "3"; 3) do
    print_string "for "; print_int i; print_newline ()
  done

let () =
  for%nop i = (print_endline "5"; 5) to (print_endline "2"; 2) do
    print_string "for "; print_int i; print_newline ()
  done

let () =
  for%nop i = (print_endline "5"; 5) downto (print_endline "2"; 2) do
    print_string "for "; print_int i; print_newline ()
  done
