-- Implements a simple library for parsing TOML.

let _pyToml = pyimport "toml"

-- Read a string in TOML format and return the corresponding record.
let tomlRead = lam tomlStr.
  pyconvert (pycall _pyToml "loads" (tomlStr,))

-- Write a dict (=record) into TOML format
let tomlWrite = lam dict.
  pyconvert (pycall _pyToml "dumps" (dict,))

mexpr

utest tomlRead "" with {} in
-- NOTE(Linnea, 2021-03-29): Empty record not supported
-- utest tomlWrite {} with "" in

utest tomlRead "# This is a comment" with {} in

let rhs = {key = {v1 = 1, v2 = 2}} in
utest tomlRead
  "# This is a comment

   [key]
   v1 = 1
   v2 = 2"
with rhs in
utest tomlWrite rhs
with
 "[key]\nv1 = 1\nv2 = 2\n"
in

let rhs =
{ title = "TOML example"
, owner = {name = "Miking Benchmarks"}
, table = {list_of_things = [1,2]}
, fruit = [ {name = "apple", shape = "round", score = 5, tag = "multi-colored"}
          , {name = "orange", shape = "round", score = 4}
          , {name = "cucumber", shape = "elongated", score = 1}]
} in
utest tomlRead
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
  " with rhs in

utest tomlRead (tomlWrite rhs) with rhs in

()
