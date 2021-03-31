include "config-scanner.mc"
include "runner.mc"
include "path.mc"
include "string.mc"

let menu = strJoin "\n" [
  "TBA"
]

let options =
  { benchmarks = ""
  , runtimes = ""
  , iters = 1
  , warmups = 1
  , output = toTOML
  , clean = true
  }

recursive let parseArgs = lam ops. lam args.
  match args with ["--benchmarks"] ++ args then
    match args with [b] ++ args then
      parseArgs {ops with benchmarks = b} args
    else error "--benchmarks with no argument"

  else match args with ["--runtimes"] ++ args then
    match args with [r] ++ args then
      parseArgs {ops with runtimes = r} args
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
    (lam t. if t.0 then () else error t.1)
    [ (pathExists ops.runtimes,
       concat "No such directory: " ops.runtimes)
    , (pathExists ops.benchmarks,
       concat "No such directory: " ops.benchmarks)
    , (gti ops.iters 0,
       "Number of iterations should be larger than 0")
    , (geqi ops.warmups 0,
       "Number of warmups cannot be negative")
    ]

let main = lam.
  let ops = parseArgs options (tail argv) in
  verifyOptions ops;

  let runtimes = findRuntimes ops.runtimes in
  match findBenchmarks ops.benchmarks [] runtimes
  with {benchmarks = benchmarks, datasets = datasets} then
    let rs = runBenchmarks benchmarks datasets runtimes ops in
    printLn (ops.output rs)
  else never

mexpr

main ()
