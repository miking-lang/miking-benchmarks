include "string.mc"
include "common.mc"
include "log.mc"

include "options.mc"
include "../tool/config-scanner.mc"
include "../tool/runner.mc"

let main = lam.
  let ops = parseArgs options (tail argv) in
  verifyOptions ops;

  let runtimes = findRuntimes ops.runtimes in
  let bs = findBenchmarks ops.benchmarks runtimes in
  let rs = runBenchmarks bs runtimes ops in
  printLn (ops.output rs)

mexpr

main ()
