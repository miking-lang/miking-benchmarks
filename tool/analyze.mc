include "string.mc"
include "runner.mc"
include "utils.mc"

let _blt = pyimport "builtins"
let _plt = pyimport "matplotlib.pyplot"

let addPlot =
  lam label.
  lam x.
  lam y.
  lam xticks.
    pycallkw _plt "plot" (x, y) {label=label};
    pycall _plt "xticks" (x, xticks);
    pycall _plt "tight_layout" ();
    ()

let finalizePlot = lam name.
  pycall _plt "legend" ();
  pycallkw _plt "ylim" () {ymin = 0.0};
  pycall _plt "savefig" (concat name ".png",);
  pycall _plt "clf" ()

let plotByData = lam root. lam filename.
  let rawResults = (tomlReadFile filename).results in

  let formatPath = lam path.
    pathWithDelim (pathRel path root) "::"
  in

  -- Group results by datasets
  let groupedResults : Map String (Map String [Result]) =
    foldl
      (lam acc. lam result : Result.
         let dataKey = formatPath result.data.cwd in
         let m =
           match mapLookup dataKey acc with Some m then m
           else mapEmpty cmpString in

         let benchKey = formatPath result.benchmark in
         let m =
           match mapLookup benchKey m with Some res then
             mapInsert benchKey (cons result res) m
           else mapInsert benchKey [result] m

         in mapInsert dataKey m acc)
      (mapEmpty cmpString)
      rawResults
  in

  let doPlots = lam dataKey : String. lam results : Map String [Result].
    let doOnePlot = lam benchKey : String. lam res : [Result].
      let n = length res in
      let xs = create n (lam i. i) in
      let xticks = map (lam r. r.data.argument) res in
      let ys = map (lam r. mean r.ms_run) res in
      addPlot benchKey xs ys xticks
    in
    map (lam r. doOnePlot r.0 r.1) (mapBindings results);
    finalizePlot dataKey
  in
  map (lam b. doPlots b.0 b.1) (mapBindings groupedResults)

mexpr
plotByData "../benchmark-suite/benchmarks" "results.toml"
