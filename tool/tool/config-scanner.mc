include "char.mc"
include "string.mc"
include "map.mc"
include "bool.mc"
include "eqset.mc"
include "common.mc"

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
           , fileName: String
           , options : [{name: String, contents: String}]
           , cwd : Path
           }

-- Manual list of options to check for
-- NOTE(dlunde,2021-06-16): This is only necessary due to the Python
-- dictionaries being converted to records in the TOML parsing (should be
-- converted to proper maps instead).
let options = lam tomlApp. [
  match tomlApp with { argument = a } then
    Some { name = "argument", contents = a } else None (),
  match tomlApp with { options = a } then
    Some { name = "options", contents = a } else None (),
  match tomlApp with { buildOptions = a } then
    Some { name = "buildOptions", contents = a } else None (),
  match tomlApp with { buildExtra = a } then
    Some { name = "buildExtra", contents = a } else None (),
  match tomlApp with { cleanExtra = a } then
    Some { name = "cleanExtra", contents = a } else None (),
  match tomlApp with { tags = a } then
    Some { name = "tags", contents = a } else None ()
]

-- Input for a benchmark
type Input = { file : Option String
             , data : Option String
             , tags : [String]
             , cwd : Path
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
  foldl (lam acc. lam root. mapUnion acc
    (pathFoldRuntime
      (lam acc. lam f. if endsWith f ".toml" then addRuntime f acc else acc)
      (mapEmpty cmpString) root)) (mapEmpty cmpString) roots

-- Convert a string into a Timing type.
let getTiming : String -> Timing = lam str.
  match str with "complete" then
    Complete ()
  else error (concat "Unknown timing option: " str)

-- A partial benchmark is used while scanning the directory for config files.
type PartialBenchmark =
  { timing : Option Timing
  , app : [App]
  , pre : Option App
  , post : [App]
  , input : [Input]
  }

let initPartialBench =
  { timing = None ()
  , app = []
  , pre = None ()
  , post = []
  , input = []
  }

-- Convert a partial benchmark into a list of benchmarks, and verify that
-- runtimes are valid.
let extractBenchmarks = -- ... -> Option Benchmark
  lam runtimes : Map String Runtime.
  lam cwd : Path.
  lam pb : PartialBenchmark.
    match pb.timing with Some timing then
      let timing: Timing = getTiming timing in
      match pb.app with [] then []
      else
        let appruns = map (lam app. app.runtime) pb.app in
        let preruns = match pb.pre with Some pre then [pre.runtime] else [] in
        let postruns = map (lam app. app.runtime) pb.post in
        match find
          (lam r. match mapLookup r runtimes with None () then true else false)
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
      let c = tomlRead (readFile configFile) in
      let cwd = pathGetParent configFile in
      let constructApp = lam tomlApp.
        { runtime = tomlApp.runtime
        , fileName = pathGetFile configFile
        , options =
            foldl (lam acc. lam arg. optionMapOr acc (snoc acc) arg)
              [] (options tomlApp)
        , cwd = match tomlApp with { base = base, cwd = cwd} then
                  error (concat "cannot define both cwd and base: " configFile)
                else match tomlApp with { base = base } then
                  pathConcat cwd base
                else match tomlApp with { cwd = cwd } then cwd
                else cwd
        }
      in
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
              concat (map constructApp app) pb.app
            else pb.app}

        -- Pre
        , lam pb. {pb with pre =
            match c with {pre = pre} then
              match pb.pre with Some oldPre then
                overrideErr "pre" configFile oldPre pre
              else Some (constructApp pre)
            else pb.pre}

        -- Post
        , lam pb. {pb with post =
            match c with {post = post} then
              concat (map constructApp post) pb.post
            else pb.post}


        -- Input
        , lam pb. {pb with input =
            match c with {input = input} then
              foldl (lam input. lam tomlInput.
                  match tomlInput with {file = _, data = _}
                  then error "Not allowed to specify both file and data" else
                  cons
                    { file =
                        match tomlInput with {file = file}
                        then Some file else None ()
                    , data =
                        match tomlInput with {data = data} then Some data
                        else None ()
                    , tags =
                        match tomlInput with {tags = tags} then tags else []
                     , cwd = cwd
                    } input)
                pb.input input
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
