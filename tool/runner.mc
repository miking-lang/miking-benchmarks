include "config-scanner.mc"
include "ocaml/process-helpers.mc"
include "string.mc"
include "path.mc"

type Result = { benchmark : String
              -- , data : String
              -- Time for building, if any, in ms
              , ms_build : Option Float
              -- Time for running the benchmark, in ms
              , ms_run : Float
              }

-- cwd? where argument is defined, should also be possible to specify?
-- build only once?
-- nIters
-- nDryruns
-- ignore dirs: ignore _*, .* and so on, should also be possible to specify

let cmdExists = lam cmd.
  true

-- Check if 'str' starts with 'prefix'
let startsWith = lam str. lam prefix.
  isPrefix eqChar prefix str

-- Replace all occurrences of substring 'old' in 'str' by substring 'new'.
let strReplace : String -> String -> String =
  lam str. lam old. lam new.
    let oldLen = length old in
    recursive let work = lam str.
      match str with "" then str
      else
        if startsWith str old then
          match splitAt str oldLen with (_, str) then
            concat new (work str)
          else never
        else cons (head str) (work (tail str))
    in work str

utest strReplace "Hello" "H" "Y" with "Yello"
utest strReplace "" "H" "Y" with ""
utest strReplace "./{argument} -- {argument}" "{argument}" "prog"
with "./prog -- prog"

let insertArg = lam cmd. lam arg.
  strReplace cmd "{argument}" arg

-- Run a given 'cmd' with a given 'stdin' in directory 'cwd'. Returns both the
-- result and the elapsed time in ms.
let runCommand : String -> String -> Path -> (ExecResult, Float) =
  lam cmd. lam stdin. lam cwd.
    let t1 = wallTimeMs () in
    let r = phRunCommand (strSplit " " cmd) stdin cwd in
    let t2 = wallTimeMs () in
    (r, subf t2 t1)

-- Build and run with a 'runtime' provided with a given 'argument'. Returns both
-- the time for building and the time for running.
let runWithRuntime = -- ... -> (Option Float, [Float])
  lam runtime : Runtime.
  lam argument : String.
  lam cwd : Path.
  lam timing : Timing.
  lam nIters : Int. -- number of times to repeat the run
  lam nDryruns : Int. -- number of times to run before starting to measure
    recursive let findSupportedCommand : [Command] -> Command  = lam commands.
      match commands with [] then
        error
          (concat "Required executables not found for runtime" runtime.provides)
      else match commands with [c] ++ commands then
        if all cmdExists c.required_executables then c
        else findSupportedCommand commands
      else never
    in
    let c = findSupportedCommand runtime.command in
    -- Build the benchmark if build command is present
    let buildMs =
      optionMap (lam cmd.
                   let buildCmd = insertArg cmd argument in
                   match runCommand buildCmd "" cwd with (_, buildMs)
                   then buildMs else never)
                c.build_command
    in
    let cmd = insertArg c.command argument in
    -- Run the benchmark
    match timing with Complete () then
      match runCommand cmd "" cwd with (_, runMs) then
        (buildMs, runMs)
      else never
    else error "Unknown timing option"

-- Run a given list of benchmarks
let runBenchmarks : [Benchmark] -> Map String Runtime -> [Result] =
  lam benchmarks.
  lam runtimes.
    foldl
      (lam acc. lam b.
         match b with {description = d, timing = t, runtime = r,
                       argument = a, cwd = cwd}
         then
           match runWithRuntime (mapFindWithExn r runtimes) a cwd t 0 0
           with (buildMs, runMs) then
             cons {benchmark = d, ms_build = buildMs, ms_run = runMs} acc
           else never
         else never)
      []
      benchmarks

-- Convert a list of results into CSV format
let toCSV : [Result] -> String =
  lam results.
    let cs = lam lst. strJoin "," lst in
    let header = cs ["benchmark", "ms_build", "ms_run"] in
    let body = map
      (lam r.
        cs [r.benchmark
           , float2string (optionGetOr 0.0 (r.ms_build))
           , float2string r.ms_run])
      results
    in strJoin "\n" (cons header body)

mexpr

let runtimes = findRuntimes "test/runtimes" in
let benchmarks = findBenchmarks "test/benchmarks" [] runtimes in

let rs = runBenchmarks benchmarks runtimes in

printLn (toCSV rs);

()
