include "toml.mc"
include "char.mc"
include "string.mc"
include "map.mc"

type Timing
-- Measure runtime end-to-end
con Complete : () -> Timing

type Command = { required_executables : [String]
               , build_command : String -> String
               , command : String -> String}
type Runtime = { provides : String
               , command : [Command]
               }
type Benchmark = { description : String
                 , timing : Timing
                 , runtime : String
                 , argument : String
                 }

type Path = String

-- Check if 'str' ends with 'suffix'
let endsWith = lam str. lam suffix.
  isSuffix eqChar suffix str

-- Check if a path exists
let pathExists : Path -> Bool = lam path.
  true

let pathConcat : Path -> Path -> Path = lam p1. lam p2.
  join [p1, "/", p2]

-- Get all the files and sub-directories in a directory
let listDir : Path -> {dirs : [Path], files : [Path]} = lam dir.
  if pathExists dir then
    let blt = pyimport "builtins" in
    let oslib = pyimport "os" in
    let walk = pycall blt "list" (pycall oslib "walk" (dir,),) in
    let lst = pyconvert walk in
    match lst with [] then
      {dirs = [], files = []}
    else match lst with [top] ++ _ then
      {dirs = top.1, files = top.2}
    else never
  else error (concat "No such directory: " dir)

-- Traverse through the directory tree, starting at root.
recursive let pathFold =
  lam f : (a -> Path -> a).
  lam acc : a.
  lam root : Path.
    let dirLst = listDir root in
    let files = map (pathConcat root) dirLst.files in
    let dirs = map (pathConcat root) dirLst.dirs in
    let acc = foldl f acc files in
    foldl (lam acc. lam dir. pathFold f acc dir) acc dirs
end

let findRuntimes : String -> Map String Runtime = lam root.
  let addRuntime = lam configFile : Path. lam runtimes : Map String Runtime.
  let r = readToml (readFile configFile) in
    mapInsert r.provides r runtimes
  in
  pathFold
    (lam acc. lam f. if endsWith f ".toml" then addRuntime f acc else acc)
    (mapEmpty cmpString)
    root

let getBenchmark =
  lam description : String.
  lam timing : Option Timing.
  lam runtime : Option Runtime.
  lam argument : Option Argument.
  match timing with Some t then
    match runtime with Some r then
      match argument with Some a then
        {description = description, timing = t, runtime = r, argument = a}
      else None ()
    else None ()
  else None ()

let getTiming = lam str.
  match str with "complete" then
    Complete ()
  else error (concat "Unknown timing option: " str)

type PartialBench =
  { timing : Option Timing
  , runtime : Option String
  , argument : Option String
  }

let isCompleteBench =
  lam b : PartialBench.
    all (lam o. match o with Some _ then true else false)
        [b.timing, b.runtime, b.argument]

let extractBench : Map String RuntimString -> PartialBench -> Benchmark = lam runtimes. lam desc. lam b.
  { description = desc
  , timing =
    let raw = optionGetOrElse (lam. error "expected timing") b.timing in
    getTiming raw
  , runtime =
    let r = optionGetOrElse (lam. error "expected runtime") b.runtime in
    mapLookupOrElse (lam. error (concat "Undefined runtime: " r)) r runtimes;
    r
  , argument = optionGetOrElse (lam. error "expected argument") b.argument
  }

-- Find benchmarks to run
let findBenchmarks : String -> [String] -> Unknown =
  lam root : Path. -- The root directory of the benchmarks
  lam paths : [Path]. -- Subpaths within root in which to look for benchmarks
  lam runtimes : Map String Runtime.

  let buildPartialBench = lam b : PartialBench. lam configFile : Path.
    let c = readToml (readFile configFile) in
    { timing =
      match c with {timing = t} then
        match b.timing with Some oldT then
          error (join [ "Overriding timing in file: ", configFile
                      , "\nPrevious definition: ", oldT
                      , "\nNew definition: ", t])
        else Some t
      else b.timing
    , runtime =
      match c with {runtime = r} then
        match b.runtime with Some oldR then
          error (join [ "Overriding runtime in file: ", configFile
                      , "\nPrevious definition: ", oldR
                      , "\nNew definition: ", r])
        else Some r
      else b.runtime
    , argument =
      match c with {argument = a} then
        match b.argument with Some oldA then
          error (join [ "Overriding argument in file: ", configFile
                      , "\nPrevious definition: ", oldA
                      , "\nNew definition: ", a])
        else Some a
      else b.argument
    }
  in

  let res =
    pathFold
      (lam acc. lam file.
         if endsWith file ".toml" then
           let b =
             buildPartialBench acc.incompleteBench file
           in
           if isCompleteBench b then
             {acc with benchmarks = cons (extractBench runtimes file b) acc.benchmarks}
           else
             {acc with incompleteBench = b}
         else
           acc
         )
      ({ benchmarks = []
       , incompleteBench = { timing = None ()
                           , runtime = None ()
                           , argument = None ()}
       })
      root
  in
  -- TODO(Linnea, 2021-03-22): Give warning or error on incompleted benchmark
  res.benchmarks

mexpr

let runtimes = findRuntimes "../benchmark-suite/runtimes" in
dprintLn (mapBindings runtimes);

let b = findBenchmarks "../benchmark-suite/benchmarks/ocaml-mcore-ocaml" "" runtimes in
dprintLn b
