include "log.mc"

include "../tool/path.mc"
include "../tool/data.mc"

let menu = strJoin "\n"
[ "Usage: mi main -- <options>"
, ""
, "Options:"
, "  --help           Print this message and exit"
, "  --benchmarks     Root directory of the benchmarks (default '.')"
, "  --runtimes       Root directory of the runtime definitions (default '.')"
, "  --iters          Number of times to repeat each benchmark (default 1)"
, "  --warmups        Number of warmup runs for each benchmark (default 1)"
, "  --output         Output format {toml} (default: toml)"
, "  --log            Specify log level (off, error, warning, info, debug, default = off)"
, "  --timeout-s      Specify a timeout in seconds (default off). Requires the command
                      line tool 'timeout' to be installed (installed by default on Linux).
                      Install on macOS via 'brew install coreutils'."
, "  --enable-clean   Clean up files after running benchmarks (default on)"
, "  --disable-clean  Do not clean up files after running benchmarks"
, "  --plot           Plot results from this file (optional)"
]

type Options =
  { benchmarks : [String]
  , runtimes : [String]
  , iters : Int
  , warmups : Int
  , output : [BenchmarkResult] -> String
  , timeoutSec : Option Float
  , clean : Bool
  , plot : Option String
  }

let options : Options =
  { benchmarks = []
  , runtimes = []
  , iters = 1
  , warmups = 1
  , output = toTOML
  , timeoutSec = None ()
  , clean = true
  , plot = None ()
  }

recursive let parseArgs = lam ops : Options. lam args : [String].
  match args with [] then
    {{ops with benchmarks = if null ops.benchmarks then ["."] else ops.benchmarks}
          with runtimes = if null ops.runtimes then ["."] else ops.runtimes}

  else match args with ["--help"] ++ args then
    printLn menu; exit 0

  else match args with ["--benchmarks"] ++ args then
    match args with [b] ++ args then
      parseArgs {ops with benchmarks = snoc ops.benchmarks (pathAbs b)} args
    else error "--benchmarks with no argument"

  else match args with ["--runtimes"] ++ args then
    match args with [r] ++ args then
      parseArgs {ops with runtimes = snoc ops.runtimes (pathAbs r)} args
    else error "--runtimes with no argument"

  else match args with ["--iters"] ++ args then
    match args with [n] ++ args then
      parseArgs {ops with iters = string2int n} args
    else error "--iters with no argument"

  else match args with ["--warmups"] ++ args then
    match args with [n] ++ args then
      parseArgs {ops with warmups = string2int n} args
    else error "--warmups with no argument"

  else match args with ["--timeout-s"] ++ args then
    match args with [n] ++ args then
      parseArgs {ops with timeoutSec = Some (string2float n)} args
    else error "--timeout-s with no argument"

  else match args with ["--output"] ++ args then
    match args with [s] ++ args then
      let s = str2lower s in
      let outFun =
          match s with "toml" then toTOML
          else error (concat "Unknown output option: " s)
      in
      parseArgs {ops with output = outFun} args
    else error "--output with no argument"

  else match args with ["--plot"] ++ args then
    match args with [a] ++ args then
      parseArgs {ops with plot = Some a} args
    else error "--plot with no argument"

  else match args with ["--enable-clean"] ++ args then
     parseArgs {ops with clean = true} args
  else match args with ["--disable-clean"] ++ args then
     parseArgs {ops with clean = false} args

  else match args with ["--log"] ++ args then
    match args with [lvl] ++ args then
      let lvl =
        switch lvl
        case "off" then logLevel.off
        case "error" then logLevel.error
        case "warning" then logLevel.warning
        case "info" then logLevel.info
        case "debug" then logLevel.debug
        case _ then error (concat "Unknown log level: " lvl)
        end
      in
      logSetLogLevel lvl;
      parseArgs ops args
    else error "--log with no argument"

  else match args with [a] ++ args then
    error (concat "Unknown argument: " a)
  else never
end

let verifyOptions = lam ops : Options.
  map
    (lam t : (Bool, String). if t.0 then () else printLn menu; error t.1)
    [ (forAll pathExists ops.runtimes,
       concat "No such directory: " (strJoin " " ops.runtimes))
    , (forAll pathExists ops.benchmarks,
       concat "No such directory: " (strJoin " " ops.benchmarks))
    , (gti ops.iters 0,
       "Number of iterations should be larger than 0")
    , (geqi ops.warmups 0,
       "Number of warmups cannot be negative")
    , (pathExists (optionGetOr "." ops.plot),
       concat "No such directory: " (optionGetOr "." ops.plot))
    ]
