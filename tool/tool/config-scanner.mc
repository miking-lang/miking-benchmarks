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

-- An instantiation of a runtime with a particular argument within a benchmark
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
    [ not (startsWith "_" path)
    , not (eqString "datasets" path)
    ]

utest dirBenchmark "hello" with true
utest dirBenchmark "_build" with false
utest dirBenchmark "datasets" with true

-- Check if 'path' is a valid directory for a runtime definition
let dirRuntime = lam path.
  all eqBool
    [ not (startsWith "_" path) ]

let pathFoldBenchmark = pathFoldDirWD dirBenchmark

let pathFoldRuntime = pathFold dirRuntime

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

-- Convert a partial benchmark into a benchmark, and verify that options are valid.
let extractBench = -- ... -> Option Benchmark
  lam runtimes : Map String Runtime.
  lam cwd : Path.
  lam pb : PartialBench.
        -- print "\n"; dprint pb; print "\n";
    match pb.timing with Some timing then
      let timing: Timing = getTiming timing in
      match pb.app with Some app then
        let preruns = match pb.pre with Some pre then [pre] else [] in
        let postruns = map (lam app. app.runtime) pb.post in
        match find
          (lam r. match mapLookup r runtimes with None () then true else false)
          (join [[app.runtime], preruns, postruns])
        with Some r then
          error (concat "Runtime does not exist: " r)
        else
          Some { timing = timing
               , app = app
               , pre = pb.pre
               , post = pb.post
               , cwd = cwd
               , input = pb.input
               }
      else None ()
    else None ()

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

  -- Update a partial benchmark 'pb' with information from 'configFile'.
  let updatePartialBench =
    lam pb : PartialBenchmark.
    lam configFile : Path.
      let c = tomlRead (readFile configFile) in
      let cwd = pathGetParent configFile in
      let updates =

      -- Timing
      [ lam pb. {pb with timing =
          match c with {timing = t} then
            match pb.timing with Some oldT then
              overrideErr "timing" configFile oldT t
            else Some t
          else pb.timing}

      -- App
      , lam pb. {pb with app =
          match c with {app = app} then
            match pb.app with Some oldA then
              overrideErr "app" configFile oldA app
            else Some app
          else pb.app}

      -- Pre
      , lam pb. {pb with pre =
          match c with {pre = pre} then
            match pb.pre with Some oldPre then
              overrideErr "pre" configFile oldPre pre
            else Some pre
          else pb.pre}

      -- Post
      , lam pb. {pb with post =
          match c with {post = post} then
            concat post pb.post
          else pb.post}


      -- Input
      , lam pb. {pb with input =
          match c with {input = input} then
            foldl (lam input. lam tomlInput.
                { file =
                    match tomlInput with {file = file}
                    then Some (pathConcat cwd file) else None (),
                  data =
                    match tomlInput with {data = data} then Some data
                    else None (),
                  tags =
                    match tomlInput with {tags = tags} then tags else []
                }
              ) pb.input c.input
          else pb.input}
      ] in

      foldl (lam acc. lam upd. upd acc) pb updates
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

      match extractBench runtimes p pb with Some bench then
        cons bench bs
      else
        if null dirs then
          error (concat "Incomplete benchmark at leaf directory position " p)
        else
          foldl (rec pb) bs dirs

  in

  rec initPartialBench [] root

mexpr

()
