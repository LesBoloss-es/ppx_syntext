let () =
  let i = ref 1 in
  while%nop print_endline "while"; !i <= 3 do
    print_string "while "; print_int !i; print_newline ();
    incr i
  done

let () =
  let i = ref 3 in
  while%nop print_endline "while"; !i <= 1 do
    print_string "while "; print_int !i; print_newline ();
    incr i
  done
