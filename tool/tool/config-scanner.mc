include "path.mc"
include "types.mc"
include "utils.mc"

-- Check if 'path' is a valid directory for a benchmark
let dirBenchmark = lam path.
  forAll (lam x. x)
    [ not (startsWith "_" path)
    , not (eqString "datasets" path)
    ]

utest dirBenchmark "hello" with true
utest dirBenchmark "_build" with false
utest dirBenchmark "datasets" with false

-- Check if 'path' is a valid directory for a runtime definition
let dirRuntime = lam path.
  forAll eqBool
    [ not (startsWith "_" path) ]

let pathFoldRuntime = pathFold dirRuntime

-- Find all the available runtimes defined in the directory 'root'.
let findRuntimes : Paths -> Map String Runtime = lam roots.
  let addRuntime = lam configFile : Path. lam runtimes : Map String Runtime.
    let r: Runtime = tomlRead configFile runtimeFromToml in
    mapInsert r.provides r runtimes
  in
  foldl (lam acc. lam root. mapUnion acc
    (pathFoldRuntime
      (lam acc. lam f. if endsWith f ".toml" then addRuntime f acc else acc)
      (mapEmpty cmpString) root)) (mapEmpty cmpString) roots

-- Convert a string into a Timing type.
let getTiming : String -> Timing = lam str.
  match str with "complete" then
    Complete ()
  else error (concat "Unknown timing option: " str)

-- Initial empty partial benchmark
let initPartialBench : PartialBenchmark =
  { timing = None ()
  , app = []
  , pre = None ()
  , post = []
  , input = []
  }

-- Convert a partial benchmark into a list of benchmarks, and verify that
-- runtimes are valid.
let extractBenchmarks : Map String Runtime -> Path -> PartialBenchmark -> [Benchmark] =
  lam runtimes : Map String Runtime.
  lam cwd : Path.
  lam pb : PartialBenchmark.
    match pb.timing with Some timing then
      match pb.app with [] then []
      else
        let appruns : [String] = map (lam app : App. app.runtime) pb.app in
        let preruns : [String] =
          match pb.pre with Some pre then
            let pre : App = pre in
            [pre.runtime]
          else []
        in
        let postruns : [String] = map (lam app : App. app.runtime) pb.post in
        match find
          (lam r : String. match mapLookup r runtimes with None () then true else false)
          (join [appruns, preruns, postruns])
        with Some r then
          error (concat "Runtime does not exist: " r)
        else
          map (lam app. { timing = timing
                        , app = app
                        , pre = pb.pre
                        , post = pb.post
                        , cwd = cwd
                        , input = pb.input
                        }) pb.app
    else []

-- Find all benchmarks by scanning the directory 'root' for configuration files.
let findBenchmarks : [Path] -> Map String Runtime -> [Benchmark] =
  lam roots : [Path]. -- The root directories of the benchmarks
  lam runtimes : Map String Runtime.

  let overrideErr =
    lam field: String.
    lam configFile: String.
    lam old: String.
    lam new: String.
    error (join [ "Overriding ", field, " in file: ", configFile
                , "\nPrevious definition: ", old
                , "\nNew definition: ", new])
  in

  -- Update a partial benchmark 'pb' with information from 'configFile'.
  let updatePartialBench =
    lam pb : PartialBenchmark.
    lam configFile : Path.
      let pb2 : PartialBenchmark =
        tomlRead configFile partialBenchmarkFromToml
      in
      let mergePartials : PartialBenchmark -> PartialBenchmark -> PartialBenchmark =
        lam pb1. lam pb2.
           let timing =
             switch (pb1.timing, pb2.timing)
             case (None (), None ()) then None ()
             case ((Some t, None ()) | (None (), Some t)) then Some t
             case (Some t1, Some t2) then overrideErr "timing" configFile t1 t2
             end
           in
           let app = concat pb1.app pb2.app in
           let pre =
             switch (pb1.pre, pb2.pre)
             case (None (), None ()) then None ()
             case ((Some p, None ()) | (None (), Some p)) then Some p
             case (Some p1, Some p2) then overrideErr "pre" configFile p1 p2
             end
           in
           let post = concat pb1.post pb2.post in
           let input = concat pb1.input pb2.input in
           { timing = timing
           , app = app
           , pre = pre
           , post = post
           , input = input
           }
      in
      mergePartials pb pb2
  in

  recursive let rec =
    lam pb: PartialBenchmark.
    lam bs: [Benchmark].
    lam p: Path.

      let ls = pathList p in
      let files = map (pathConcat p) ls.files in
      let dirs = map (pathConcat p) (filter dirBenchmark ls.dirs) in

      let pb = foldl (lam pb. lam file.
          if endsWith file ".toml" then updatePartialBench pb file
          else pb
        ) pb files in

      let benchmarks = extractBenchmarks runtimes p pb in
      if null benchmarks
      then foldl (rec pb) bs dirs
      else
        let resDirs = foldl (lam acc. lam dir. concat acc
          (rec initPartialBench [] dir)) [] dirs
        in
        join [benchmarks, bs, resDirs]

    -- TODO(Linnea, 2021-03-22): Give warning or error on incompleted benchmark

  in

  foldl (lam acc. lam root. concat acc
    (rec initPartialBench [] root)) [] roots

mexpr

()
