let rec fibonacci n =
  if n < 3 then
    1
  else
    fibonacci (n-1) + fibonacci (n-2)

let _ =
  let n = int_of_string (read_line ()) in
  print_endline (string_of_int (fibonacci n))
