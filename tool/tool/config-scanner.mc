include "char.mc"
include "string.mc"
include "map.mc"
include "bool.mc"
include "eqset.mc"

include "path.mc"
include "toml.mc"
include "utils.mc"

type Timing
-- Don't measure the time
con NoTiming : () -> Timing
-- Measure runtime end-to-end
con Complete : () -> Timing

-- A specific instance of a runtime
type Command = { required_executables : [String]
               , build_command : Option String
               , command : String
               , clean_command : Option String
               }

-- A build and run procedure
type Runtime = { provides : String
               , command : [Command]
               }

-- An instantiation of a runtime with a particular argument
type App = { runtime : String
           , argument : String
           }

-- Input for a benchmark
type Input = { file : Option String
             , data : Option String
             , tags : [String]
             }

-- A benchmark to run
type Benchmark = { timing : Timing
                 , app : App
                 , pre : Option App
                 , post : [App]
                 , cwd : Path
                 , input : [Input]
                 }

-- Check if 'path' is a valid directory for a benchmark
let dirBenchmark = lam path.
  all (lam x. x)
    [ not (startsWith "_" path) ]

utest dirBenchmark "hello" with true
utest dirBenchmark "_build" with false
utest dirBenchmark "datasets" with true

-- Check if 'path' is a valid directory for a runtime definition
let dirRuntime = lam path.
  all eqBool
    [ not (startsWith "_" path) ]

let pathFoldBenchmark = pathFoldDirWD dirBenchmark

let pathFoldRuntime = pathFold dirRuntime

let pathFoldData = pathFold dirData

-- Find all the available runtimes defined in the directory 'root'.
let findRuntimes : Path -> Map String Runtime = lam root.
  let addRuntime = lam configFile : Path. lam runtimes : Map String Runtime.
    let r = tomlRead (readFile configFile) in
    let r: Runtime = {
      provides = r.provides,
      command =
        map (lam c: Command. {
            required_executables = c.required_executables,
            build_command =
              match c with {build_command = bc} then Some bc else None (),
            command = c.command,
            clean_command =
              match c with {clean_command = cc} then Some cc else None ()
          })
          r.command
    } in mapInsert r.provides r runtimes
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

-- Check if a partial benchmark can be converted into a benchmark.
let isCompleteBench : PartialBench -> Bool = lam b.
  all (lam o. match o with Some _ then true else false)
      [b.timing, b.runtime, b.argument]

-- Convert a partial benchmark into a benchmark, and verify that options are valid.
let extractBench = -- ... -> Option Benchmark
  lam runtimes : Map String Runtime.
  lam cwd : Path.
  lam pb : PartialBench.
    match pb.timing with Some timing then
      let timing: Timing = getTiming timing in
      match pb.app with Some app then
        match pb.pre with Some pre then
          let postruns = map (lam app. app.runtime) pb.post in
          match mapOption
            (lam r. mapLookup r runtimes)
            (join [[app.runtime], [pre.runtime], postruns])
          with Some _ then
            { timing = timing
            , app = app
            , pre = pre
            , post = pb.post
            , cwd = cwd
            , input = pb.input
            }
          else None ()
        else None ()
      else None ()
    else None ()
    -- TODO: Incorporate error messages above
    -- { timing =
    --   let raw = optionGetOrElse (lam. error "expected timing") b.timing in
    --   getTiming raw
    -- , runtime =
    --   let r = optionGetOrElse (lam. error "expected runtime") b.runtime in
    --   mapLookupOrElse (lam. error (concat "Undefined runtime: " r)) r runtimes;
    --   r
    -- , argument = optionGetOrElse (lam. error "expected argument") b.argument
    -- , cwd = cwd
    -- , data = b.data
    -- }

-- Find all benchmarks by scanning the directory 'root' for configuration files.
let findBenchmarks = -- ... -> {benchmarks : [Benchmark]}
  lam root : Path. -- The root directory of the benchmarks
  lam paths : [Path]. -- Subpaths within root in which to look for benchmarks TODO(Linnea, 2021-03-23): not supported yet
  lam runtimes : Map String Runtime.

  -- A partial benchmark is used while scanning the directory for config files.
  type PartialBenchmark =
    { timing : Option Timing
    , app : Option App
    , pre : Option App
    , post : [App]
    , input : [Input]
    }
  in

  let initPartialBench =
    { timing = None ()
    , app = None ()
    , pre = None ()
    , post = []
    , input = []
    }
  in

  let overrideErr =
    lam field: String.
    lam configFile: String.
    lam old: String.
    lam new: String.
    error (join [ "Overriding ", field, " in file: ", configFile
                , "\nPrevious definition: ", old
                , "\nNew definition: ", new])
  in

  -- Update a partial benchmark 'b' with information from 'configFile'.
  let updatePartialBench =
    lam b : PartialBenchmark.
    lam configFile : Path.
      let c = tomlRead (readFile configFile) in
      let cwd = pathGetParent configFile in
      let updates =

      -- Timing
      [ lam b. {b with timing =
          match c with {timing = t} then
            match b.timing with Some oldT then
              overrideErr "timing" configFile oldT t
            else Some t
          else b.timing}

      -- App
      , lam b. {b with app =
          match c with {app = app} then
            match b.app with Some oldA then
              overrideErr "app" configFile oldA app
            else Some app
          else b.app}

      -- Pre
      , lam b. {b with pre =
          match c with {pre = pre} then
            match b.pre with Some oldPre then
              overrideErr "pre" configFile oldPre pre
            else Some pre
          else b.pre}

      -- Post
      , lam b. {b with post = concat c.post pb.post}

      -- Input
      , lam b. {b with input = foldl (lam input. lam tomlInput.
            { file =
                match tomlInput with {file = file}
                then Some (pathConcat cwd file) else None (),
              data =
                match tomlInput with {data = data} then Some data else None (),
              tags =
                match tomlInput with {tags = tags} then tags else []
            }
          ) b.input c.input}
      ] in

      foldl (lam acc. lam upd. upd acc) b updates
  in

  match pathFoldBenchmark
    (lam acc. lam files.
       match acc with (partialBench, benchmarks) then

         let cwd = -- TODO: How to get this?
         -- Update partial benchmark with all files in current dir
         let partialBench = foldl (lam pb. lam file.
           if endsWith file ".toml" then updatePartialBench pb file
           else pb
         ) partialBench files in

         -- If benchmark is complete, add it to the accumulated set of benchmarks
         if isCompleteBench partialBench then
           (partialBench, cons (extractBench runtimes cwd partialBench) benchmarks)
         else
           (partialBench, benchmarks)
       else never)
    initPartialBench
    []
    root
  with (_, benchmarks) then benchmarks
  else never
  -- TODO(Linnea, 2021-03-22): Give warning or error on incompleted benchmark

mexpr

()
