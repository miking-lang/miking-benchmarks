include "../tool/config-scanner.mc"
include "../tool/runner.mc"
include "../tool/path.mc"
include "../tool/post-process.mc"
include "string.mc"
include "common.mc"

let menu = strJoin "\n"
[ "Usage: mi main -- <options>"
, ""
, "Options:"
, "  --help           Print this message and exit"
, "  --benchmarks     Root directory of the benchmarks (default '.')"
, "  --runtimes       Root directory of the runtime definitions (default '.')"
, "  --iters          Number of times to repeat each benchmark (default 1)"
, "  --warmups        Number of warmup runs for each benchmark (default 1)"
, "  --output         Output format {csv,toml}"
, "  --enable-clean   Clean up files after running benchmarks (default on)"
, "  --disable-clean  Do not clean up files after running benchmarks"
, "  --plot           Plot results from this file (optional)"
]

let options =
  { benchmarks = "."
  , runtimes = "."
  , iters = 1
  , warmups = 1
  , output = toTOML
  , clean = true
  , plot = None ()
  }

recursive let parseArgs = lam ops. lam args.
  match args with ["--help"] ++ args then
    printLn menu; exit 0

  else match args with ["--benchmarks"] ++ args then
    match args with [b] ++ args then
      parseArgs {ops with benchmarks = pathAbs b} args
    else error "--benchmarks with no argument"

  else match args with ["--runtimes"] ++ args then
    match args with [r] ++ args then
      parseArgs {ops with runtimes = pathAbs r} args
    else error "--runtimes with no argument"

  else match args with ["--iters"] ++ args then
    match args with [n] ++ args then
      parseArgs {ops with iters = string2int n} args
    else error "--iters with no argument"

  else match args with ["--warmups"] ++ args then
    match args with [n] ++ args then
      parseArgs {ops with warmups = string2int n} args
    else error "--warmups with no argument"

  else match args with ["--output"] ++ args then
    match args with [s] ++ args then
      let s = str2lower s in
      let outFun =
          match s with "csv" then toCSV
          else match s with "toml" then toTOML
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

  else match args with [] then ops
  else match args with [a] ++ args then
    error (concat "Unknown argument: " a)
  else never
end

let verifyOptions = lam ops.
  map
    (lam t. if t.0 then () else printLn menu; error t.1)
    [ (pathExists ops.runtimes,
       concat "No such directory: " ops.runtimes)
    , (pathExists ops.benchmarks,
       concat "No such directory: " ops.benchmarks)
    , (gti ops.iters 0,
       "Number of iterations should be larger than 0")
    , (geqi ops.warmups 0,
       "Number of warmups cannot be negative")
    , (pathExists (optionGetOr "." ops.plot),
       concat "No such directory: " (optionGetOr "." ops.plot))
    ]

let main = lam.
  let ops = parseArgs options (tail argv) in
  verifyOptions ops;

  match ops.plot with Some f then --TODO(Linnea, 2021-03-07): use separate
                                  -- scripts for running and post-processing
    plotByData ops.benchmarks f
  else
    let runtimes = findRuntimes ops.runtimes in
    let bs = findBenchmarks ops.benchmarks [] runtimes in
    let rs = runBenchmarks bs runtimes ops in
    printLn (ops.output rs)

mexpr

main ()
