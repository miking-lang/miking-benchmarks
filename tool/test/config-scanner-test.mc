include "../config-scanner.mc"

mexpr

let runtimes = findRuntimes "runtimes" in
utest mapBindings runtimes with
[ ("MCore", { provides = "MCore"
            , command = [{ required_executables = ["boot.mi"]
                         , build_command = None ()
                         , command = "boot.mi {argument}.mc"}]})
, ("OCaml", { provides = "OCaml"
            , command = [{ required_executables = ["dune"]
                         , build_command = Some "dune build"
                         , command = "_build/default/{argument}.exe"}]})
]
in

let benchAndData = findBenchmarks "benchmarks" [] runtimes in

match benchAndData with {benchmarks = benchmarks, datasets = datasets} then

utest mapKeys datasets with ["1.txt", "2.txt"] in

utest benchmarks with
[ { description = "benchmarks/hello/mcore/config.toml"
  , argument = "hello"
  , runtime = "MCore"
  , timing = Complete ()
  , cwd = "benchmarks/hello/mcore"
  , data = ["1.txt", "2.txt"]
  }
, { description = "benchmarks/hello/ocaml/config.toml"
  , argument = "hello"
  , runtime = "OCaml"
  , timing = Complete ()
  , cwd = "benchmarks/hello/ocaml"
  , data = ["1.txt", "2.txt"]
  }
] in ()

else never;

()
