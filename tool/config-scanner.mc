include "toml.mc"
include "char.mc"
include "string.mc"
include "map.mc"
include "path.mc"
include "bool.mc"

type Timing
-- Measure runtime end-to-end
con Complete : () -> Timing

type Command = { required_executables : [String]
               , build_command : Option String
               , command : String}
type Runtime = { provides : String
               , command : [Command]
               }
type Benchmark = { description : String
                 , timing : Timing
                 , runtime : String
                 , argument : String
                 , cwd : Path
                 -- , data : Unknown -- TODO(Linnea, 2021-03-23): scanning of data sets are not supported yet
                 }

-- Check if 'str' starts with 'prefix'
let startsWith = lam prefix. lam str.
  isPrefix eqChar prefix str

-- Check if 'str' ends with 'suffix'
let endsWith = lam str. lam suffix.
  isSuffix eqChar suffix str

-- Check if 'path' is a valid directory for a benchmark
let dirBenchmark = lam path.
  all (lam x. x)
    [ not (startsWith "_" path)
    , not (eqString "datasets" path)
    ]

utest dirBenchmark "hello" with true
utest dirBenchmark "_build" with false
utest dirBenchmark "datasets" with false

-- Check if 'path' is a valid directory for a runtime definition
let dirRuntime = lam path.
  all eqBool
    [ not (startsWith "_" path) ]

let pathFoldBenchmark = pathFoldWD dirBenchmark

let pathFoldRuntime = pathFold dirRuntime

-- Find all the available runtimes defined in the directory 'root'.
let findRuntimes : Path -> Map String Runtime = lam root.
  let addRuntime = lam configFile : Path. lam runtimes : Map String Runtime.
    let r = readToml (readFile configFile) in
    let r = { provides = r.provides
            , command =
              map (lam c. { required_executables = c.required_executables
                          , build_command = match c with {build_command = bc}
                                            then Some bc else None ()
                          , command = c.command})
                  r.command}
    in mapInsert r.provides r runtimes
  in
  pathFoldRuntime
    (lam acc. lam f. if endsWith f ".toml" then addRuntime f acc else acc)
    (mapEmpty cmpString)
    root

-- Convert a string into a Timing type.
let getTiming : String -> Timing = lam str.
  match str with "complete" then
    Complete ()
  else error (concat "Unknown timing option: " str)

-- A partial benchmark is used while scanning the directory for config files.
type PartialBench =
  { timing : Option Timing
  , runtime : Option String
  , argument : Option String
  }

-- Check if a partial benchmark can be converted into a benchmark.
let isCompleteBench : PartialBench -> Bool = lam b.
  all (lam o. match o with Some _ then true else false)
      [b.timing, b.runtime, b.argument]

-- Convert a partial benchmark into a benchmark, and verify that options are valid.
let extractBench : Map String RuntimString -> PartialBench -> Benchmark =
  lam runtimes. lam desc. lam cwd. lam b.
    { description = desc
    , timing =
      let raw = optionGetOrElse (lam. error "expected timing") b.timing in
      getTiming raw
    , runtime =
      let r = optionGetOrElse (lam. error "expected runtime") b.runtime in
      mapLookupOrElse (lam. error (concat "Undefined runtime: " r)) r runtimes;
      r
    , argument = optionGetOrElse (lam. error "expected argument") b.argument
    , cwd = cwd
    }

-- Find all benchmarks by scanning the directory 'root' for configuration files.
let findBenchmarks : String -> [String] -> Unknown =
  lam root : Path. -- The root directory of the benchmarks
  lam paths : [Path]. -- Subpaths within root in which to look for benchmarks TODO(Linnea, 2021-03-23): not supported yet
  lam runtimes : Map String Runtime.

  -- Update a partial benchmark 'b' with information from 'configFile'.
  let updatePartialBench = lam b : PartialBench. lam configFile : Path.
    let c = readToml (readFile configFile) in
    { timing =
      match c with {timing = t} then
        match b.timing with Some oldT then
          error (join [ "Overriding timing in file: ", configFile
                      , "\nPrevious definition: ", oldT
                      , "\nNew definition: ", t])
        else Some t
      else b.timing
    , runtime =
      match c with {runtime = r} then
        match b.runtime with Some oldR then
          error (join [ "Overriding runtime in file: ", configFile
                      , "\nPrevious definition: ", oldR
                      , "\nNew definition: ", r])
        else Some r
      else b.runtime
    , argument =
      match c with {argument = a} then
        match b.argument with Some oldA then
          error (join [ "Overriding argument in file: ", configFile
                      , "\nPrevious definition: ", oldA
                      , "\nNew definition: ", a])
        else Some a
      else b.argument
    }
  in

  match pathFoldBenchmark
    (lam acc. lam file.
       match acc with (partialBench, benchmarks) then
         if endsWith file ".toml" then
           let cwd = pathGetParent file in
           let b = updatePartialBench partialBench file in
           if isCompleteBench b then
             (partialBench, cons (extractBench runtimes file cwd b) benchmarks)
           else
             (b, benchmarks)
         else
           acc
       else never
       )
    {timing = None (), runtime = None (), argument = None ()}
    []
    root
  with (_, benchmarks) then benchmarks
  else never
  -- TODO(Linnea, 2021-03-22): Give warning or error on incompleted benchmark

mexpr

()
