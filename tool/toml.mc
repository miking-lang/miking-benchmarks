-- Implements a simple library for parsing TOML.

-- Read a string in TOML format and return the corresponding record.
let readToml = lam tomlStr.
  let pytoml = pyimport "toml" in
  pyconvert (pycall pytoml "loads" (tomlStr,))

mexpr

utest readToml "" with {} in
utest readToml "# This is a comment" with {} in
utest readToml
  "# This is a comment

   [key]
   v1=1
   v2=2"
with {key = {v1 = 1, v2 = 2}} in
utest readToml
  "
  # This is a TOML example.

  title = \"TOML example\"

  [owner]
  name = \"Miking Benchmarks\"

  [table]
  list_of_things = [
  1,
  2
  ]

  [[fruit]]
  name = \"apple\"
  shape = \"round\"
  score = 5
  tag = \"multi-colored\"

  [[fruit]]
  name = \"orange\"
  shape = \"round\"
  score = 4

  [[fruit]]
  name = \"cucumber\"
  shape = \"elongated\"
  score = 1
  " with {
    title = "TOML example",
    owner = {name = "Miking Benchmarks"},
    table = {list_of_things = [1,2]},
    fruit = [{name = "apple", shape = "round", score = 5, tag = "multi-colored"},
             {name = "orange", shape = "round", score = 4},
             {name = "cucumber", shape = "elongated", score = 1}]
  } in

()
