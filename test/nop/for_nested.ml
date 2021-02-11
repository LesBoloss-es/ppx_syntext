let () =
  for%nop i = (print_endline "1"; 1) to (print_endline "3"; 3) do
    for%nop j = (print_endline "75"; 75) downto (print_endline "71"; 71); do
      Format.printf "for %d %d\n" i j
    done
  done
