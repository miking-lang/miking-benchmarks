include "../config-scanner.mc"

mexpr

let runtimes = findRuntimes "runtimes" in
utest mapBindings runtimes with
[ ("MCore", { provides = "MCore"
            , command = [{ required_executables = ["boot.mi"]
                         , command = "boot.mi {argument}.mc"}]})
, ("OCaml", { provides = "OCaml"
            , command = [{ required_executables = ["dune"]
                         , build_command = "dune build"
                         , command = "_build/default/{argument}.exe"}]})
]
in

let benchmarks = findBenchmarks "benchmarks" [] runtimes in

utest benchmarks with
[ { description = "benchmarks/hello/mcore/config.toml"
  , argument = "hello"
  , runtime = "MCore"
  , timing = Complete ()
  }
, { description = "benchmarks/hello/ocaml/config.toml"
  , argument = "hello"
  , runtime = "OCaml"
  , timing = Complete ()}
] in

()
