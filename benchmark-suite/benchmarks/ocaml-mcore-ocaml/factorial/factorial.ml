let factorial n =
  let rec helper acc n =
    if n > 0 then
      helper (acc * n) (n - 1)
    else
      acc
  in
  helper 1 n

let a =
  let n = int_of_string (read_line ()) in
  factorial n
