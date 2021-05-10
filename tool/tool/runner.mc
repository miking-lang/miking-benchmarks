include "ocaml/sys.mc"
include "path.mc"
include "config-scanner.mc"
include "utils.mc"
include "common.mc"

type Result = { input : Input
              -- Time for building, if any, in ms
              , ms_build : Option Float
              -- Time for running the benchmark, in ms
              , ms_run : [Float]
              -- Stdouts for each post-processing step
              , post : [{ app: App, stdout: [String] }]
              }

type BenchmarkResult = { app: App, results: [Result] }

type Options = { iters : Int
               , warmups : Int
               }

-- Used as dummy data object for benchmarks without data. We could use option
-- type in result type, but this simplifies writing to toml.
let inputEmpty : Data = {runtime = "", argument = "", cwd = "", tags = []}

let instantiateCmd = lam cmd. lam app.
  match app
  with { argument = argument, options = options, buildOptions = buildOptions }
  then
    foldl (lam cmd. lam f. f cmd) cmd [
      lam cmd. strReplace cmd "{argument}" argument,
      lam cmd. strReplace cmd "{options}" options,
      lam cmd. strReplace cmd "{buildOptions}" buildOptions
    ]
  else never

-- Run a given 'cmd' with a given 'stdin' in directory 'cwd'. Returns both the
-- result and the elapsed time in ms.
let runCommand : String -> String -> Path -> (ExecResult, Float) =
  lam cmd. lam stdin. lam cwd.
    let stdin = join ["\"", escapeString stdin, "\""] in
    let cmd = (strSplit " " cmd) in

    let t1 = wallTimeMs () in
    let r = sysRunCommand cmd stdin cwd in
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
                    , "cwd: ", cwd, "\n"
                    ])
    else never

-- Like 'runCommandFailOnExit' but only returns the elapsed time.
let runCommandTime : String -> String -> Path -> Float =
  lam cmd. lam stdin. lam cwd.
    match runCommandFailOnExit cmd stdin cwd with (_, ms)
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
          if all pathIsCmd c.required_executables then c
          else rec commands
        else never
      in
      rec runtime.command
    in

    let runOpCmd : Option String -> String -> Option Float = lam cmd. lam app.
      optionMap (lam cmd.
                   let fullCmd = instantiateCmd cmd app in
                   runCommandTime fullCmd "" app.cwd)
                cmd
    in

    -- Build and run an App without timing or cleaning. Returns stoud for App.
    let runApp: App -> String -> String =
      lam app: App.
      lam stdin: String.

        let runtime: Runtime = mapFindWithExn app.runtime runtimes in
        let appSupportedCmd = findSupportedCommand runtime in
        runOpCmd appSupportedCmd.build_command app;
        let cmd = instantiateCmd appSupportedCmd.command app in
        match runCommandFailOnExit cmd stdin app.cwd with (res, _) then
          res.stdout
        else never
    in


    -- Run the benchmark for a particular Input
    -- let runBench : String -> (Option Float, [Float]) = lam stdin.
    let runInput: Input -> Result =
      lam input: Input.

        let runtime: Runtime = mapFindWithExn app.runtime runtimes in
        let appSupportedCmd = findSupportedCommand runtime in

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
          let run = lam. runCommandFailOnExit cmd stdin app.cwd in
          let runMany = lam n. map run (create n (lam. ())) in

          -- Run warmup (and throw away results)
          runMany ops.warmups;

          -- Run the benchmark
          let res: [(ExecResult, Float)] = runMany ops.iters in

          -- Collect execution times
          let times: [Float] = map (lam t. t.1) res in

          -- Collect stdouts
          let stdouts: [String] = map (lam t. (t.0).stdout) res in

          -- Run clean command
          (if ops.clean then
             runOpCmd appSupportedCmd.clean_command app
           else ());

          -- Run postprocessing on stdouts
          let post = map (lam app. {
              app = app,
              stdout = map (lam stdin. runApp app stdin) stdouts
            }) post
          in

          -- Return the final Result
          { input = input, ms_build = buildMs, ms_run = times, post = post }

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

-- Convert a list of results into CSV format
-- TODO(dlunde,2021-05-09): Not up to date
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

-- Convert a list of benchmark results into TOML format
let toTOML : [BenchmarkResult] -> String =
  lam results.
    -- Remove the option types from the results (not supported by TOML writer)
    let results =
      map (lam br.
        { br
          with results =
            map (lam r.
                   {{ r
                      with ms_build = optionGetOr 0.0 r.ms_build }
                      with input =
                        {{ r.input
                           with
                           file = optionGetOr "" r.input.file }
                           with
                           data = optionGetOr "" r.input.data } })
              br.results
        }
      ) results in
    tomlWrite { benchmark = results }
