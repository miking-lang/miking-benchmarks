include "log.mc"
include "sys.mc"

include "path.mc"
include "data.mc"
include "utils.mc"

include "../main/options.mc"

type Result = { input : Input
              -- Time for building, if any, in ms
              , ms_build : Option Float
              -- Time for running the benchmark, in ms
              , ms_run : [Float]
              -- Stdouts for each post-processing step
              , post : [{ app: App, output: [String] }]
              -- The verbatim command that was run to produce the result
              , command : String
              }

type BenchmarkResult = { app: App, results: [Result], buildCommand : String }

-- Used as dummy data object for benchmarks without data. We could use option
-- type in result type, but this simplifies writing to toml.
let inputEmpty : Input = {file = None (), data = Some "", tags = [], cwd = ""}

let instantiateCmd = lam cmd : String. lam app : App.
  foldl (lam cmd. lam opt : AppOption.
    strReplace cmd (join ["{",opt.name,"}"]) opt.contents
  ) cmd app.options

utest instantiateCmd "foo {option1} {option2}"
  {runtime = "", fileName = "",
   options = [{name = "option1", contents = "con1"}, {name = "option2", contents = "con2"}],
   cwd = "."}
with "foo con1 con2"

-- Run a given 'cmd' with a given 'stdin' in directory 'cwd'. Returns both the
-- result and the elapsed time in ms.
let runCommand : Options -> String -> String -> Path -> (ExecResult, Float) =
  lam ops. lam cmd. lam stdin. lam cwd.
    let stdin = join ["\"", escapeString stdin, "\""] in
    let cmd = (strSplit " " cmd) in

    logMsg logLevel.info (strJoin "\n"
    [ ""
    , concat "running command: " (strJoin " " cmd)
    , concat "stdin: " stdin
    , concat "cwd: " cwd
    , join ["timeout: ", (optionMapOr "none" float2string ops.timeoutSec), " s"]
    , ""
    ]);

    match sysRunCommandWithTimingTimeout ops.timeoutSec cmd stdin cwd with (ms, r) then
      logMsg logLevel.info (strJoin "\n"
      [ ""
      , concat "stdout: " r.stdout
      , concat "stderr: " r.stderr
      , concat "returncode: " (int2string r.returncode)
      , concat "elapsed ms: " (float2string ms)
      , ""
      ]);
      (r, ms)
    else never

-- Like 'runCommand' but only returns the elapsed time.
let runCommandTime : Options -> String -> String -> Path -> Float =
  lam ops. lam cmd. lam stdin. lam cwd.
    match runCommand ops cmd stdin cwd with (_, ms)
    then ms
    else never

-- Run one benchmark
let runBenchmark = -- ... -> BenchmarkResult
  lam benchmark : Benchmark.
  lam runtimes : Map String Runtime.
  lam ops : Options.
  match benchmark with {
    timing = timing,
    app = app,
    pre = pre,
    post = post,
    cwd = cwd,
    input = input
  } then

    let findSupportedCommand: Runtime -> Command = lam runtime.
      recursive let rec = lam commands.
        match commands with [] then
          error (concat
            "Required executables not found for runtime" runtime.provides)
        else match commands with [c] ++ commands then
          let c : Command = c in
          if forAll pathIsCmd c.required_executables then c
          else rec commands
        else never
      in
      rec runtime.command
    in

    -- Run an optional command without timeout
    let runOpCmd : Option String -> App -> Option Float = lam cmd. lam app.
      optionMap (lam cmd.
                   let fullCmd = instantiateCmd cmd app in
                   runCommandTime {ops with timeoutSec = None ()} fullCmd "" app.cwd)
                cmd
    in

    -- Build and run an App without timing or cleaning. Returns stoud for App.
    let runApp: App -> String -> String =
      lam app: App.
      lam stdin: String.

        let runtime: Runtime = mapFindExn app.runtime runtimes in
        let appSupportedCmd = findSupportedCommand runtime in
        runOpCmd appSupportedCmd.build_command app;
        let cmd = instantiateCmd appSupportedCmd.command app in
        match runCommand ops cmd stdin app.cwd with (res, _) then
          if eqi res.returncode 0 then res.stdout else res.stderr
        else never
    in

    let runtime: Runtime = mapFindExn app.runtime runtimes in
    let appSupportedCmd = findSupportedCommand runtime in

    -- Run the benchmark for a particular Input
    let runInput: Input -> Result =
      lam input: Input.

        -- Retrieve stdin from input
        let stdin =
          match input with { file = Some file, data = None () } then
            readFile (pathConcat input.cwd file)
          else match input with { file = None (), data = Some data } then
            data
          else error "Invalid input entry"
        in

        -- Run preprocessor, if specified
        let stdin = match pre with Some pre then runApp pre stdin else stdin in

        -- Build the benchmark
        let buildMs = runOpCmd appSupportedCmd.build_command app in

        let cmd = instantiateCmd appSupportedCmd.command app in
        match timing with Complete () then
          let run = lam. runCommand ops cmd stdin app.cwd in
          let runMany = lam n. map run (create n (lam. ())) in

          -- Run warmup (and throw away results)
          runMany ops.warmups;

          -- Run the benchmark
          let res: [(ExecResult, Float)] = runMany ops.iters in

          -- Collect execution times
          let times: [Float] = map (lam t : (ExecResult, Float). t.1) res in

          -- Collect outputs
          let stdouts: [String] = map (lam t : (ExecResult, Float).
            if eqi (t.0).returncode 0 then (t.0).stdout else (t.0).stderr
          ) res in

          -- Run clean command
          (if ops.clean then
             runOpCmd appSupportedCmd.clean_command app
           else ());

          -- Run postprocessing on outputs
          let post = map (lam app. {
              app = app,
              output = map (lam stdin. runApp app stdin) stdouts
            }) post
          in

          -- Return the final Result
          { input = input, ms_build = buildMs, ms_run = times, post = post, command = cmd }

        else error "Unknown timing option"
    in

    { app = app
    , results =
        match input with [] then
          -- If there is no input, simply run the benchmark once for some dummy
          -- input
          [runInput inputEmpty]
        else
          map runInput input
    , buildCommand =
      switch appSupportedCmd.build_command
      case Some cmd then instantiateCmd cmd app
      case None () then ""
      end
    }

  else never

-- Run a given list of benchmarks
let runBenchmarks = -- ... -> [BenchmarkResult]
  lam benchmarks : [Benchmark].
  lam runtimes : Map String Runtime.
  lam ops : Options.
    foldl
      (lam acc. lam b.
         cons (runBenchmark b runtimes ops) acc)
      [] benchmarks
