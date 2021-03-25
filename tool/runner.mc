include "ocaml/process-helpers.mc"
include "string.mc"
include "path.mc"

type Result = { benchmark : String
              -- , data : String
              -- Time for building, if any, in ms
              , ms_build : Option Float
              -- Time for running the benchmark, in ms
              , ms_run : [Float]
              }

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

-- Like runCommand but fail on exit code different than 0
let runCommandFailOnExit : String -> String -> Path -> (ExecResult, Float) =
  lam cmd. lam stdin. lam cwd.
    match runCommand cmd stdin cwd with (r, ms) then
      if eqi r.returncode 0 then (r, ms)
      else
        error (join ["Command ", cmd, "\n"
                    , " failed with exit code ", int2string r.returncode, "\n"
                    , "Stdout: ", r.stdout, "\n"
                    , "Stderr: ", r.stderr, "\n"
                    ])
    else never

-- Like 'runCommandFailOnExit' but only returns the elapsed time.
let runCommandTime : String -> String -> Path -> (ExecResult, Float) =
  lam cmd. lam stdin. lam cwd.
    match runCommandFailOnExit cmd stdin cwd with (_, ms)
    then ms
    else never

-- Build and run with a 'runtime' provided with a given 'argument'. Returns both
-- the time for building and the time for running.
let runWithRuntime = -- ... -> (Option Float, [Float])
  lam runtime : Runtime.
  lam argument : String.
  lam cwd : Path.
  lam timing : Timing.
  lam nDryruns : Int. -- number of times to run before starting to measure
  lam nIters : Int. -- number of times to repeat the run
    recursive let findSupportedCommand : [Command] -> Command  = lam commands.
      match commands with [] then
        error
          (concat "Required executables not found for runtime" runtime.provides)
      else match commands with [c] ++ commands then
        if all pathIsCmd c.required_executables then c
        else findSupportedCommand commands
      else never
    in
    let c = findSupportedCommand runtime.command in
    -- Build the benchmark if build command is present
    let buildMs =
      optionMap (lam cmd.
                   let buildCmd = insertArg cmd argument in
                   runCommandTime buildCmd "" cwd)
                c.build_command
    in
    let cmd = insertArg c.command argument in
    -- Run the benchmark
    match timing with Complete () then
      let run = lam. runCommandTime cmd "" cwd in
      let runMany = lam n. map run (create n (lam. ())) in
      -- Throw away the result for the dry runs
      runMany nDryruns;
      -- Now collect the measurements
      let times = runMany nIters in
      (buildMs, times)
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
           match runWithRuntime (mapFindWithExn r runtimes) a cwd t 1 5
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
           , join ["{", cs (map float2string r.ms_run), "}"]])
      results
    in strJoin "\n" (cons header body)
