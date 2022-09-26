include "log.mc"
include "sys.mc"

include "path.mc"
include "types.mc"
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

let logInitMsg = lam cmd. lam stdin. lam cwd. lam ops.
  (strJoin "\n"
    (join [ [""]
    , [join ["running command: ", strJoin " " cmd]]
    , if logLevelPrinted logLevel.debug then [join ["stdin: ", (stdin ())]] else []
    , [join ["cwd: ", cwd]]
    , [join ["timeout: ", optionMapOr "none" float2string ops.timeoutSec, " s"]]
    , [""]
    ]))

let logResMsg = lam stdout. lam stderr. lam r. lam ms.
  (strJoin "\n"
    (join [ [""]
    , if logLevelPrinted logLevel.debug then [join ["stdout: ", stdout ()]] else []
    , if logLevelPrinted logLevel.debug then [join ["stderr: ", stderr ()]] else []
    , [join ["returncode: ", int2string r]]
    , [join ["elapsed ms: ", float2string ms]]
    , [""]
    ]))

-- Run a given 'cmd' with a given 'stdin' in directory 'cwd'. Returns both the
-- result and the elapsed time in ms.
let runCommandFileIO
    : Options -> String -> String -> String -> String -> Path
      -> (Float, ReturnCode) =
  lam ops. lam cmd. lam stdinFile. lam stdoutFile. lam stderrFile. lam cwd.
    let cmd = (strSplit " " cmd) in
    logMsg logLevel.info (lam. logInitMsg cmd (lam. readFile stdinFile) cwd ops);
    match sysRunCommandWithTimingTimeoutFileIO
            ops.timeoutSec cmd stdinFile stdoutFile stderrFile cwd
    with (ms,r) & res in
    logMsg logLevel.info
      (lam. logResMsg (lam. readFile stdoutFile) (lam. readFile stderrFile) r ms);
    res

let runCommand: Options -> String -> String -> Path -> (Float, ExecResult) =
  lam ops. lam cmd. lam stdin. lam cwd.
    let cmd = (strSplit " " cmd) in
    logMsg logLevel.info (lam. logInitMsg cmd (lam. stdin) cwd ops);
    match sysRunCommandWithTimingTimeout ops.timeoutSec cmd stdin cwd
    with (ms,r) & res in
    logMsg logLevel.info (lam. logResMsg (lam. r.stdout) (lam. r.stderr) r.returncode ms);
    res

-- Like 'runCommand' but only returns the elapsed time.
let runCommandTime : Options -> String -> String -> Path -> Float =
  lam ops. lam cmd. lam stdin. lam cwd.
    match runCommand ops cmd stdin cwd with (ms, _) in ms

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
            "Required executables not found for runtime " runtime.provides)
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

    -- Build and run an App without timing or cleaning. Returns a filename
    -- containing the stdout for the App.
    let runApp: App -> String -> String =
      lam app: App.
      lam stdinFile: String.
        let stdoutFile = sysTempFileMake () in
        let stderrFile = sysTempFileMake () in
        let runtime: Runtime = mapFindExn app.runtime runtimes in
        let appSupportedCmd = findSupportedCommand runtime in
        runOpCmd appSupportedCmd.build_command app;
        let cmd = instantiateCmd appSupportedCmd.command app in
        match runCommandFileIO ops cmd stdinFile stdoutFile stderrFile app.cwd
        with (_, r) in
        if eqi r 0 then sysDeleteFile stderrFile; stdoutFile
        else sysDeleteFile stdoutFile; stderrFile
    in

    let runtime: Runtime = mapFindExn app.runtime runtimes in
    let appSupportedCmd = findSupportedCommand runtime in

    -- Run the benchmark for a particular Input
    let runInput: Input -> Result =
      lam input: Input.

        -- Set up standard input file
        let stdinFile =
          match input with { file = Some file, data = None () } then
            pathConcat input.cwd file
          else match input with { file = None (), data = Some data } then
            let f = sysTempFileMake () in
            writeFile f data;
            f
          else error "Invalid input entry"
        in

        -- Run preprocessor, if specified
        let stdinFile = match pre with Some pre then
            let outFile = runApp pre stdinFile in
            sysDeleteFile stdinFile; outFile
          else stdinFile
        in

        -- Build the benchmark
        let buildMs = runOpCmd appSupportedCmd.build_command app in

        let cmd = instantiateCmd appSupportedCmd.command app in
        match timing with Complete () then
          let run: () -> (Float, ReturnCode, String, String) = lam.
            let stdoutFile = sysTempFileMake () in
            let stderrFile = sysTempFileMake () in
            match runCommandFileIO ops cmd
                    stdinFile stdoutFile stderrFile app.cwd
            with (ms, r) in
            (ms, r, stdoutFile, stderrFile)
          in
          let runMany = lam n. map run (create n (lam. ())) in

          -- Run warmup (and throw away results)
          let wress = runMany ops.warmups in
          iter (lam wres. sysDeleteFile wres.2; sysDeleteFile wres.3; ()) wress;

          -- Run the benchmark
          let res: [(Float, ReturnCode, String, String)] = runMany ops.iters in

          -- Collect execution times
          let times: [Float] = map (lam t. t.0) res in

          -- Collect file names containing outputs
          let stdoutFiles: [String] = map (lam t.
            if eqi t.1 0 then sysDeleteFile t.3; t.2 else sysDeleteFile t.2; t.3
          ) res in

          -- Run clean command
          (if ops.clean then
             runOpCmd appSupportedCmd.clean_command app; ()
           else ());

          -- Run postprocessing on outputs
          let post = map (lam app. {
              app = app,
              output = map (lam stdinFile.
                  let outFile = runApp app stdinFile in
                  let res = readFile outFile in
                  sysDeleteFile stdinFile; sysDeleteFile outFile;
                  res
                ) stdoutFiles
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
let runBenchmarks = -- ... -> ()
  lam benchmarks : [Benchmark].
  lam runtimes : Map String Runtime.
  lam ops : Options.
    iter
      (lam b.
         let res: BenchmarkResult = runBenchmark b runtimes ops in
         -- Append res in correct format to output file
         sysAppendFile ops.output (ops.format [res]);
         ()
      )
      benchmarks
