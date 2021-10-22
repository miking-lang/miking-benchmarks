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
  printLn "finished scanning runtimes";
  let bs = findBenchmarks ops.benchmarks runtimes in
  printLn "finished scanning benchmarks";
  let rs = runBenchmarks bs runtimes ops in
  printLn "finished running benchmarks";
  printLn (ops.output rs)

mexpr

main ()
