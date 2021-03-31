include "../config-scanner.mc"

mexpr

let runtimes = findRuntimes "runtimes" in
utest mapBindings runtimes with
[ ("MCore", { provides = "MCore"
            , command = [{ required_executables = ["boot.mi"]
                         , build_command = None ()
                         , command = "boot.mi {argument}.mc"
                         , clean_command = None ()}]})
, ("OCaml", { provides = "OCaml"
            , command = [{ required_executables = ["dune"]
                         , build_command = Some "dune build"
                         , command = "_build/default/{argument}.exe"
                         , clean_command = None ()}]})
]
in

let benchAndData = findBenchmarks "benchmarks" [] runtimes in

match benchAndData with {benchmarks = benchmarks, datasets = datasets} then

let dataKeys =
[ "benchmarks/hello/datasets:1.txt"
, "benchmarks/hello/datasets:2.txt"]
in

utest mapKeys datasets with dataKeys in

utest benchmarks with
[ { description = "benchmarks/hello/mcore/config.toml"
  , argument = "hello"
  , runtime = "MCore"
  , timing = Complete ()
  , cwd = "benchmarks/hello/mcore"
  , data = dataKeys
  }
, { description = "benchmarks/hello/ocaml/config.toml"
  , argument = "hello"
  , runtime = "OCaml"
  , timing = Complete ()
  , cwd = "benchmarks/hello/ocaml"
  , data = dataKeys
  }
] in ()

else never;

()
