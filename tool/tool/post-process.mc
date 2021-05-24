include "string.mc"
include "runner.mc"
include "utils.mc"
include "plot.mc"

-- Create one plot per dataset, with the data on the x-axis and the mean of the
-- runtime on the y-axis. Each benchmark using that dataset will get a separate
-- curve within the plot.
let plotByData = lam root. lam filename.
  let rawResults = (tomlReadFile filename).benchmark in

  let formatPath = lam path.
    pathWithDelim (pathRel path root) "::"
  in

  -- Group the raw results by used dataset
  let groupedResults : Map String (Map String [Result]) =
    foldl
      (lam acc. lam benchResult : BenchmarkResult.
         (foldl
            (lam acc. lam result : Result.
               let inputKey = formatPath result.input.cwd in
               let m =
                 match mapLookup inputKey acc with Some m then m
                 else mapEmpty cmpString in

               let benchKey = formatPath benchResult.app.cwd in
               let m =
                 match mapLookup benchKey m with Some res then
                   mapInsert benchKey (cons result res) m
                 else mapInsert benchKey [result] m
               in mapInsert inputKey m acc)
          acc
          benchResult.results))
      (mapEmpty cmpString)
      rawResults
  in

  -- Check if the data can be interpreted as numbers. In that case, they should
  -- be spaced appropriately on the x-axis. Otherwise, a linear spacing will be
  -- used.
  let xAxisFromTicks : [String] -> [Int] = lam ticks.
    -- Trim any leading zeros
    let ticks = map (trimPrefix "0") ticks in
    if all stringIsInt ticks then
      map string2int ticks
    -- TODO(Linnea, 2021-04-07): Also check for floats
    else
      create (length ticks) (lam i. i)
  in

  let doPlots = lam inputKey : String. lam results : Map String [Result].
    let doOnePlot = lam benchKey : String. lam res : [Result].
      let n = length res in
      let xticks = map (lam r. r.input.data) res in
      let xs = xAxisFromTicks xticks in
      let ys = map (lam r. mean r.ms_run) res in
      plotAddPlot benchKey xs ys xticks
    in
    map (lam r. doOnePlot r.0 r.1) (mapBindings results);
    plotFinalizePlot plotDefaultOptions inputKey
  in
  map (lam b. doPlots b.0 b.1) (mapBindings groupedResults)
