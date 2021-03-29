include "ocaml/process-helpers.mc"
include "string.mc"
include "path.mc"
include "config-scanner.mc"

type Result = { benchmark : String
              , data : String
              -- Time for building, if any, in ms
              , ms_build : Option Float
              -- Time for running the benchmark, in ms
              , ms_run : [Float]
              }

type Options = { nIters : Int
               , warmups : Int
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
                    , "failed with exit code ", int2string r.returncode, "\n"
                    , "Stdin: ", stdin, "\n"
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

-- Run one benchmark
let runBenchmark = -- ... -> [Result]
  lam benchmark : Benchmark.
  lam datasets : Map String Data.
  lam runtimes : Map String Runtime.
  lam ops : Options.
  match benchmark with { runtime = runtimeID, data = data,
                         argument = argument, cwd = cwd, timing = timing } then
    let runtime = mapFindWithExn runtimeID runtimes in

    recursive let findSupportedCommand : [Command] -> Command  = lam commands.
      match commands with [] then
        error
          (concat "Required executables not found for runtime" runtime.provides)
      else match commands with [c] ++ commands then
        if all pathIsCmd c.required_executables then c
        else findSupportedCommand commands
      else never
    in

    let build : String Option -> String -> Float Option = lam cmd. lam arg.
      optionMap (lam cmd.
                   let buildCmd = insertArg cmd arg in
                   runCommandTime buildCmd "" cwd)
                cmd
    in

    let benchSupportedCmd = findSupportedCommand runtime.command in

    -- Run the benchmark with a given stdin
    let runBench = lam stdin.
      -- Build the benchmark
      let buildMs = build benchSupportedCmd.build_command argument in
      -- Run the benchmark
      let cmd = insertArg benchSupportedCmd.command argument in
        match timing with Complete () then
          let run = lam. runCommandTime cmd stdin cwd in
          let runMany = lam n. map run (create n (lam. ())) in
          -- Throw away the result for the warmup runs
          runMany ops.warmups;
          -- Now collect the measurements
          let times = runMany ops.iters in
          (buildMs, times)
        else error "Unknown timing option"
    in

    match data with [] then
      match runBench "" with (buildMs, times) then
        [{ benchmark = benchmark.description
         , data = ""
         , ms_build = buildMs
         , ms_run = times
         }]
      else never
    else
      foldl (lam acc. lam dKey.
        let d = mapFindWithExn dKey datasets in
        match d with {argument = arg, runtime = rID, cwd = cwd} then
          let r = mapFindWithExn rID runtimes in
          let c = findSupportedCommand r.command in
          build c.build_command arg;
          let runCmd = insertArg c.command arg in
          -- Run the dataset program and get the stdout, use as stdin for
          -- benchmark
          match runCommandFailOnExit runCmd "" cwd with (res, _) then
            match runBench res.stdout with (buildMs, times) then
               cons
                 { benchmark = benchmark.description
                 , data = dKey
                 , ms_build = buildMs
                 , ms_run = times
                 }
                 acc
            else never
          else never
        else never)
        []
        data
  else never

-- Run a given list of benchmarks
let runBenchmarks = -- ... -> [Result]
  lam benchmarks : [Benchmark].
  lam datasets : Map String Data.
  lam runtimes : Map String Runtime.
  lam ops : Options.
    foldl
      (lam acc. lam b.
         concat (runBenchmark b datasets runtimes ops) acc)
      [] benchmarks

-- Convert a list of results into CSV format
let toCSV : [Result] -> String =
  lam results.
    let cs = lam lst. strJoin "," lst in
    let header = cs ["benchmark", "data", "ms_build", "ms_run"] in
    let body = map
      (lam r.
        cs [ r.benchmark
           , r.data
           , float2string (optionGetOr 0.0 (r.ms_build))
           , join ["{", cs (map float2string r.ms_run), "}"]])
      results
    in strJoin "\n" (cons header body)

-- Convert a list of results into TOML format
let toTOML : [Result] -> String =
  lam results.
    -- Remove the option types from the results (not supported by TOML writer)
    let results =
      map (lam r.
        { benchmark = r.benchmark
        , data = r.data
        , ms_build = optionGetOr 0.0 r.ms_build
        , ms_run = r.ms_run
        }
      ) results in
    tomlWrite {results = results}
