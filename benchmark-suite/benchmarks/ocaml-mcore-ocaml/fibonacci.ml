let rec fibonacci n =
  if n < 3 then
    1
  else
    fibonacci (n-1) + fibonacci (n-2)

let _ =
  print_endline (string_of_int (fibonacci 20))
