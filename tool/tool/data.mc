
include "ext/toml-ext.mc"
include "common.mc"
include "path.mc"

-- Defines the data types used for storing benchmark configurations and results.

let _lookupKeyConvert = lam convertFun. lam key. lam m.
  mapFindApplyOrElse
    (lam v. Some (convertFun v))
    (lam. None ()) key m

type Path = String

-- TODO: where to put these helper types?

type Timing
-- Don't measure the time
con NoTiming : () -> Timing
-- Measure runtime end-to-end
con Complete : () -> Timing

let timingEq = lam t1. lam t2.
  switch (t1, t2)
  case (NoTiming (), NoTiming ()) then true
  case (Complete (), Complete ()) then true
  case _ then false
  end

-- Read a toml config file and apply convert function.
let tomlRead : Path -> (Path -> TomlTable -> a) -> a =
  lam fileName : Path.
  lam convertFun : Path -> TomlTable -> a.
    let s = readFile fileName in
    let t = tomlFromStringExn s in
    convertFun fileName t

-------------------
-- READABLE DATA --
-------------------

-- Data types that are read from configuration files should implement a function
-- '<type>FromToml : Path -> TomlTable -> <type>'.

-- A specific instance of a runtime
type Command =
{ required_executables : [String]
, build_command : Option String
, command : String
, clean_command : Option String
}

-- A build and run procedure
type Runtime =
{ provides : String
, command : [Command]
}

-- An instantiation of a runtime with a particular argument within a benchmark
type AppOption = {name : String, contents : String}
type App =
{ runtime : String
, fileName: String
, options : [AppOption]
, cwd : Path
}

-- Input for a benchmark
type Input =
{ file : Option String
, data : Option String
, tags : [String]
, cwd : Path
}

-- A partial benchmark is used while scanning the directory for config files.
type PartialBenchmark =
{ timing : Option Timing
, app : [App]
, pre : Option App
, post : [App]
, input : [Input]
}

-- A benchmark to run (extracted from a PartialBenchmark)
type Benchmark =
{ timing : Timing
, app : App
, pre : Option App
, post : [App]
, cwd : Path
, input : [Input]
}

let commandFromToml : Path -> TomlTable -> Command = lam. lam cmd : TomlTable.
  let m = tomlTableToMap cmd in
  let cmd = tomlValueToStringExn (mapFindWithExn "command" m) in
  let reqExe = tomlValueToStringSeqExn (mapFindWithExn "required_executables" m) in
  let buildCmd = mapFindApplyOrElse
    (lam v. Some (tomlValueToStringExn v))
    (lam. None ())
    "build_command" m
  in
  let cleanCmd = mapFindApplyOrElse
    (lam v. Some (tomlValueToStringExn v))
    (lam. None ())
    "clean_command" m
  in
  { required_executables = reqExe
  , command = cmd
  , build_command = buildCmd
  , clean_command = cleanCmd
  }

utest commandFromToml "path/to/config.toml" (tomlFromStringExn
"
required_executables = [\"dune\", \"rm\"]
build_command = \"dune build\"
command = \"_build/default/{argument}.exe\"
clean_command = \"rm -rf _build\"
")
with
{ required_executables = ["dune", "rm"]
, build_command = Some "dune build"
, command = "_build/default/{argument}.exe"
, clean_command = Some "rm -rf _build"
}

let runtimeFromToml : Path -> TomlTable -> Runtime = lam fileName. lam table : TomlTable.
  let m = tomlTableToMap table in
  let cmds : [TomlTable] = tomlValueToTableSeqExn (mapFindWithExn "command" m) in
  let cmds = map (commandFromToml fileName) cmds in
  { provides = tomlValueToStringExn (mapFindWithExn "provides" m)
  , command = cmds
  }

utest runtimeFromToml "path/to/config.toml" (tomlFromStringExn
"
provides = \"OCaml\"

[[command]]
required_executables = [\"dune\", \"rm\"]
build_command = \"dune build\"
command = \"_build/default/{argument}.exe\"
clean_command = \"rm -rf _build\"

[[command]]
required_executables = []
command = \"someOtherCommand\"
")
with
{ provides = "OCaml"
, command =
  [ { required_executables = ["dune", "rm"]
    , build_command = Some "dune build"
    , command = "_build/default/{argument}.exe"
    , clean_command = Some "rm -rf _build"
    }
  , { required_executables = []
    , build_command = None ()
    , command = "someOtherCommand"
    , clean_command = None ()
    }
  ]
}

let inputFromToml : Path -> TomlTable -> Input =
  lam fileName. lam table : TomlTable.
    let m = tomlTableToMap table in
    let file = _lookupKeyConvert tomlValueToStringExn "file" m in
    let data = _lookupKeyConvert tomlValueToStringExn "data" m in
    (match (file, data) with (Some _, Some _)
     then error (join ["Not allowed to specify both file and data: ", fileName])
     else ());
    let tags = mapFindApplyOrElse
      (lam v. tomlValueToStringSeqExn v)
      (lam. [])
      "tags" m
    in
    { file = file
    , data = data
    , tags = tags
    , cwd = pathGetParent fileName
    }

utest inputFromToml "path/to/config.toml" (tomlFromStringExn
"
tags = [\"random\"]
file = \"datasets/random1.txt\"
")
with
{ file = Some "datasets/random1.txt"
, data = None ()
, tags = ["random"]
, cwd = "path/to"
}

utest inputFromToml "path/to/config.toml" (tomlFromStringExn
"
tags = [\"random\"]
data = \"some data\"
")
with
{ file = None ()
, data = Some "some data"
, tags = ["random"]
, cwd = "path/to"
}

let appFromToml : Path -> TomlTable -> App =
  lam fileName. lam table : TomlTable.
    let m = tomlTableToMap table in
    let runtime = tomlValueToStringExn (mapFindWithExn "runtime" m) in
    let cwd = pathGetParent fileName in
    let cwdApp =
      switch (mapLookup "cwd" m, mapLookup "base" m)
      case (Some cwd, Some base) then
        error (concat "cannot define both cwd and base: " fileName)
      case (Some cwdApp, None ()) then tomlValueToStringExn cwdApp
      case (None (), Some base) then
        pathConcat cwd (tomlValueToStringExn base)
      case (None (), None ()) then cwd
      end
    in
    -- Remove all key-values that we have already taken care of
    let m = mapRemove "cwd" m in
    let m = mapRemove "runtime" m in
    let m = mapRemove "base" m in
    -- Parse remaining key-values as strings. In this way, we allow arbitrary
    -- options (but they must have strings as values).
    let options = map (lam bind : (String, TomlValue).
      {name = bind.0, contents = tomlValueToStringExn bind.1})
      (mapBindings m)
    in
    { runtime = runtime
    , fileName = pathGetFile fileName
    , options = options
    , cwd = cwdApp
    }

utest
let app =
appFromToml "path/to/config.toml" (tomlFromStringExn
"
runtime = \"CorePPL\"
argument = \"crbd.mc\"
buildOptions = \"-j 32 --stack_size 1000\"
options = \"8192\"
importantInfo = \"some_info\"
") in
let o1 : {name : String, contents : String} = get app.options 0 in
let o2 : {name : String, contents : String} = get app.options 1 in
let o3 : {name : String, contents : String} = get app.options 2 in
let o4 : {name : String, contents : String} = get app.options 3 in
[ app.runtime, app.fileName, app.cwd
, o1.name, o1.contents
, o2.name, o2.contents
, o3.name, o3.contents
, o4.name, o4.contents
]
with
[ "CorePPL", "config.toml", "path/to"
, "options", "8192"
, "argument", "crbd.mc"
, "buildOptions", "-j 32 --stack_size 1000"
, "importantInfo", "some_info"
]

let partialBenchmarkFromToml : Path -> TomlTable -> PartialBenchmark =
  lam fileName. lam table : TomlTable.
    -- Convert a string into a Timing type.
    let getTiming : String -> Timing = lam str.
      match str with "complete" then Complete ()
      else error (concat "Unknown timing option: " str)
    in

    let m = tomlTableToMap table in
    let timing = mapFindApplyOrElse
      (lam v. Some (getTiming (tomlValueToStringExn v)))
      (lam. None ())
      "timing" m
    in
    let pre = mapFindApplyOrElse
      (lam v.
         let t = tomlValueToTableExn v in
         Some (appFromToml fileName t))
      (lam. None ())
      "pre" m
    in
    let app = mapFindApplyOrElse
      (lam v.
         let ts = tomlValueToTableSeqExn v in
         map (appFromToml fileName) ts)
      (lam. [])
      "app" m
    in
    let post = mapFindApplyOrElse
      (lam v.
         let ts = tomlValueToTableSeqExn v in
         map (appFromToml fileName) ts)
      (lam. [])
      "post" m
    in
    let input = mapFindApplyOrElse
      (lam v.
         let ts = tomlValueToTableSeqExn v in
         map (inputFromToml fileName) ts)
      (lam. [])
      "input" m
    in

    { timing = timing
    , app = app
    , pre = pre
    , post = post
    , input = input
    }

utest
let b =
partialBenchmarkFromToml "path/to/config.toml" (tomlFromStringExn
"
timing = \"complete\"

[pre]
runtime = \"MCore\"
argument = \"pre\"
base = \"pre\"

[[app]]
runtime = \"MCore\"
argument = \"insertsort\"

[[post]]
runtime = \"MCore\"
argument = \"post\"
base = \"post-1\"
tag = \"tag-post-1\"
"
) in
[ b.timing
, b.pre
, b.app
, b.post
, b.input
]
with
[ Some (Complete ())
, Some ({runtime = "MCore", fileName = "config.toml",
         options = [{name = "argument", contents = "pre"}],
         cwd = "path/to/pre"})
, [{runtime = "MCore", fileName = "config.toml",
    options = [{name = "argument", contents = "insertsort"}],
    cwd = "path/to"}]
, [{runtime = "MCore", fileName = "config.toml",
    options = [{name = "tag", contents = "tag-post-1"},{name = "argument", contents = "post"}],
    cwd = "path/to/post-1"}]
, []
]
-------------------
-- WRITABLE DATA --
-------------------

-- Data types that are written to output should implement a function
-- '<type>ToToml : <type> -> TomlTable

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

-- Convert a list of benchmark results into TOML format
let toTOML : [BenchmarkResult] -> String = lam results. ""
