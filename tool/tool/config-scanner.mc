include "toml.mc"
include "char.mc"
include "string.mc"
include "map.mc"
include "path.mc"
include "bool.mc"
include "utils.mc"
include "eqset.mc"

type Timing
-- Don't measure the time
con NoTiming : () -> Timing
-- Measure runtime end-to-end
con Complete : () -> Timing

type Command = { required_executables : [String]
               , build_command : Option String
               , command : String
               , clean_command : Option String}
type Runtime = { provides : String
               , command : [Command]
               }
type Data = { runtime : String
            , argument : String
            , cwd : Path
            , tags : [String]
            }
type Benchmark = { timing : Timing
                 , runtime : String
                 , argument : String
                 , cwd : Path
                 , data : [Data]
                 }

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

-- Check if 'path' is a valid directory for a dataset definition
let dirData = lam path.
  all eqBool
    [ not (startsWith "_" path) ]

let pathFoldBenchmark = pathFoldWD dirBenchmark

let pathFoldRuntime = pathFold dirRuntime

let pathFoldData = pathFold dirData

-- Find all the available runtimes defined in the directory 'root'.
let findRuntimes : Path -> Map String Runtime = lam root.
  let addRuntime = lam configFile : Path. lam runtimes : Map String Runtime.
    let r = tomlRead (readFile configFile) in
    let r = { provides = r.provides
            , command =
              map (lam c. { required_executables = c.required_executables
                          , build_command = match c with {build_command = bc}
                                            then Some bc else None ()
                          , command = c.command
                          , clean_command = match c with {clean_command = cc}
                                            then Some cc else None ()})
                  r.command}
    in mapInsert r.provides r runtimes
  in
  pathFoldRuntime
    (lam acc. lam f. if endsWith f ".toml" then addRuntime f acc else acc)
    (mapEmpty cmpString)
    root

-- Find all the datasets in the directory 'root'
let findData : Path -> Map String Data = lam root.
  let addData = lam configFile : Path. lam data : Map String Data.
    let d = tomlRead (readFile configFile) in
    let cwd = pathGetParent configFile in
    match d with {runtime = r, dataset = dataset} then
      foldl (lam acc. lam entry.
        let id = join [cwd, ":", entry.argument] in
        mapInsert id
         { runtime = r
         , argument = entry.argument
         , cwd = cwd
         , tags = match entry with {tags = tags} then tags else []
         } acc)
       data
       dataset
    else never
  in
  pathFoldData
    (lam acc. lam f. if endsWith f ".toml" then addData f acc else acc)
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
  , data : [Data]
  }

-- Check if a partial benchmark can be converted into a benchmark.
let isCompleteBench : PartialBench -> Bool = lam b.
  all (lam o. match o with Some _ then true else false)
      [b.timing, b.runtime, b.argument]

-- Convert a partial benchmark into a benchmark, and verify that options are valid.
let extractBench = -- ... -> Benchmark
  lam runtimes : Map String Runtime.
  lam cwd : Path.
  lam b : PartialBench.
    { timing =
      let raw = optionGetOrElse (lam. error "expected timing") b.timing in
      getTiming raw
    , runtime =
      let r = optionGetOrElse (lam. error "expected runtime") b.runtime in
      mapLookupOrElse (lam. error (concat "Undefined runtime: " r)) r runtimes;
      r
    , argument = optionGetOrElse (lam. error "expected argument") b.argument
    , cwd = cwd
    , data = b.data
    }

-- Find all benchmarks by scanning the directory 'root' for configuration files.
let findBenchmarks = -- ... -> {benchmarks : [Benchmark], datasets : Map String Data}
  lam root : Path. -- The root directory of the benchmarks
  lam paths : [Path]. -- Subpaths within root in which to look for benchmarks TODO(Linnea, 2021-03-23): not supported yet
  lam runtimes : Map String Runtime.

  let addData = lam pb : PartialBench. lam dataStr : String.
    {pb with data = eqsetUnion eqString  pb.data dataStr} in

  -- Update a partial benchmark 'b' with information from 'configFile'.
  let updatePartialBench =
    lam b : PartialBench.
    lam configFile : Path.
    lam data : [Data].
      let c = tomlRead (readFile configFile) in
      let updates =
      [ lam b. {b with timing =
          match c with {timing = t} then
            match b.timing with Some oldT then
              error (join [ "Overriding timing in file: ", configFile
                          , "\nPrevious definition: ", oldT
                          , "\nNew definition: ", t])
            else Some t
          else b.timing}
      , lam b. {b with runtime =
          match c with {runtime = r} then
            match b.runtime with Some oldR then
              error (join [ "Overriding runtime in file: ", configFile
                          , "\nPrevious definition: ", oldR
                          , "\nNew definition: ", r])
            else Some r
          else b.runtime}
      , lam b. {b with argument =
          match c with {argument = a} then
            match b.argument with Some oldA then
              error (join [ "Overriding argument in file: ", configFile
                          , "\nPrevious definition: ", oldA
                          , "\nNew definition: ", a])
            else Some a
          else b.argument}
      , lam b. addData b data
      ] in
      foldl (lam acc. lam upd. upd acc) b updates
  in

  match pathFoldBenchmark
    (lam acc. lam file.
       match acc with (partialBench, benchAndData) then
       match benchAndData with {benchmarks = benchmarks, datasets = datasets}
       then
         let cwd = pathGetParent file in
         match pathList cwd with {dirs = dirs} then
           -- Scan for any new datasets
           let newData =
             match find (eqString "datasets") dirs with Some _ then
               findData (pathConcat cwd "datasets")
             else mapEmpty cmpString
           in
           match
             if endsWith file ".toml" then
               -- Update the benchmark
               let b = updatePartialBench partialBench file (mapKeys newData) in
               if isCompleteBench b then
                 (partialBench,
                   { benchAndData with
                     benchmarks = cons (extractBench runtimes cwd b)
                                       benchmarks })
               else
                 (b, benchAndData)
             else
               (addData partialBench (mapKeys newData), benchAndData)
           with (pb, bd) then
             (pb, {bd with datasets = mapUnion bd.datasets newData})
           else never
         else never
       else never else never
       )
    {timing = None (), runtime = None (), argument = None (), data = []}
    {benchmarks = [], datasets = mapEmpty cmpString}
    root
  with (_, benchAndData) then benchAndData
  else never
  -- TODO(Linnea, 2021-03-22): Give warning or error on incompleted benchmark

mexpr

()
