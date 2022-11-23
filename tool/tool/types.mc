
include "ext/toml-ext.mc"
include "common.mc"
include "path.mc"

-- Defines the data types used for storing benchmark configurations and results.

let _lookupKeyConvert = lam convertFun.
  mapFindApplyOrElse
    (lam v. Some (convertFun v))
    (lam. None ())

-----------------------
-- DATA DECLARATIONS --
-----------------------

type Timing
-- Measure runtime end-to-end
con Complete : () -> Timing

let string2timing : String -> Timing = lam str.
  match str with "complete" then Complete ()
  else error (concat "Unknown timing option: " str)

let timing2string : Timing -> String = lam t.
  match t with Complete () in "complete"

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
, warnings : [String]
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

-- Stdouts of post process application, one per each output from the benchmark
type PostResult = { app: App, output: [String] }

-- Result for a specific input
type Result = { input : Input
              -- Time for building, if any, in ms
              , ms_build : Option Float
              -- Time for running the benchmark, in ms
              , ms_run : [Float]
              -- Stdouts for each post-processing step
              , post : [PostResult]
              -- The verbatim command that was run to produce the result
              , command : String
              }

-- Result over all inputs
type BenchmarkResult = { app: App, results: [Result], buildCommand : String }

-- All benchmark results
type CollectedResult = [BenchmarkResult]

-------------------
-- READABLE DATA --
-------------------

-- Data types that are read from configuration files should implement a function
-- '<type>FromToml : Path -> TomlTable -> <type>'.

-- Read a toml config file and apply convert function.
let tomlRead : all a. Path -> (Path -> TomlTable -> a) -> a =
  lam fileName : Path.
  lam convertFun : Path -> TomlTable -> a.
    let s = readFile fileName in
    let t = tomlFromStringExn s in
    convertFun fileName t

let commandFromToml : Path -> TomlTable -> Command = lam. lam cmd : TomlTable.
  let m = tomlTableToMap cmd in
  let cmd = tomlValueToStringExn (mapFindExn "command" m) in
  let reqExe = tomlValueToStringSeqExn (mapFindExn "required_executables" m) in
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
  let cmds : [TomlTable] = tomlValueToTableSeqExn (mapFindExn "command" m) in
  let cmds = map (commandFromToml fileName) cmds in
  { provides = tomlValueToStringExn (mapFindExn "provides" m)
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
    let runtime = tomlValueToStringExn (mapFindExn "runtime" m) in
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

    -- TODO(dlunde,2022-11-23): The below is useful to clean up paths (leading
    -- to, e.g., nicer log output). However, it breaks some of the utests in
    -- this file.
    -- let cwdApp = pathAbs cwdApp in

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
buildOptions = \"-j 32 --stack-size 1000\"
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
, "buildOptions", "-j 32 --stack-size 1000"
, "importantInfo", "some_info"
]

let partialBenchmarkFromToml : Path -> TomlTable -> PartialBenchmark =
  lam fileName. lam table : TomlTable.
    let m = tomlTableToMap table in
    let timing = mapFindApplyOrElse
      (lam v. Some (string2timing (tomlValueToStringExn v)))
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
    , warnings = []
    }

utest
  partialBenchmarkFromToml "path/to/config.toml" (tomlFromStringExn
  "
  timing = \"complete\"

  [[app]]
  runtime = \"MCore\"
  argument = \"insertsort\"

  [[post]]
  runtime = \"MCore\"
  argument = \"post\"
  base = \"post-1\"
  tag = \"tag-post-1\"
  "
) with {
  timing = Some (Complete ()),
  app =  [{ runtime = "MCore", fileName = "config.toml",
            options = [{name = "argument", contents = "insertsort"}],
            cwd = "path/to" }],
  pre = None (),
  post = [{ runtime = "MCore", fileName = "config.toml",
            options = [ {name = "tag", contents = "tag-post-1"},
                        {name = "argument", contents = "post"}],
            cwd = "path/to/post-1" }],
  input = [],
  warnings = []
}

utest
  let b = partialBenchmarkFromToml "path/to/config.toml" (tomlFromStringExn
  "
  timing = \"complete\"

  [[app]]
  runtime = \"MCore\"
  argument = \"insertsort\"

  [pre]
  runtime = \"MCore\"
  argument = \"pre\"
  base = \"pre\"

  [[post]]
  runtime = \"MCore\"
  argument = \"post\"
  base = \"post-1\"
  tag = \"tag-post-1\"
  "
) in optionGetOrElse (lam. error "PartialBenchmark test failed") b.pre
  with { runtime = "MCore", fileName = "config.toml",
         options = [{name = "argument", contents = "pre"}],
         cwd = "path/to/pre" }

-------------------
-- WRITABLE DATA --
-------------------

-- Data types that are written to output should implement a function
-- '<type>ToToml : <type> -> TomlTable

let _strEqNoWhitespace = lam s1. lam s2.
  let s1 = filter (lam c. not (isWhitespace c)) s1 in
  let s2 = filter (lam c. not (isWhitespace c)) s2 in
  eqString s1 s2

let inputToToml : Input -> TomlTable = lam i : Input.
  let binds =
    match i.file with Some file then [("file", tomlStringToValue file)] else []
  in
  let binds =
    match i.data with Some data then cons ("data", tomlStringToValue data) binds else binds
  in
  tomlFromBindings (concat binds
  [ ("cwd", tomlStringToValue i.cwd)
  , ("tags", tomlStringSeqToValue i.tags)
  ]
  )

utest tomlToString (inputToToml
{ file = Some "file.txt"
, data = Some "data"
, tags = []
, cwd = "path/to"
}
)
with
"
cwd = \"path/to\"
data = \"data\"
file = \"file.txt\"
tags = []
"
using _strEqNoWhitespace

let appOptionToToml : AppOption -> TomlTable = lam ao.
  tomlFromBindings
  [ ("name", tomlStringToValue ao.name)
  , ("contents", tomlStringToValue ao.contents)
  ]

utest tomlToString (appOptionToToml
{name = "name", contents = "contents"})
with
"
contents = \"contents\"
name = \"name\"
"
using _strEqNoWhitespace

let appToToml : App -> TomlTable = lam app.
  tomlFromBindings
  [ ("runtime", tomlStringToValue app.runtime)
  , ("fileName", tomlStringToValue app.fileName)
  , ("cwd", tomlStringToValue app.cwd)
  , ("options", tomlTableSeqToValue (map appOptionToToml app.options))
  ]

utest tomlToString (appToToml
{ runtime = "runtime"
, fileName = "fileName"
, cwd = "cwd"
, options = [{name = "name", contents = "contents"}]
})
with
"
cwd = \"cwd\"
fileName = \"fileName\"
runtime = \"runtime\"
[[options]]
contents = \"contents\"
name = \"name\"
"
using _strEqNoWhitespace

let postResultToToml : PostResult -> TomlTable = lam pr : PostResult.
  tomlFromBindings
  [ ("app", tomlTableToValue (appToToml pr.app))
  , ("output", tomlStringSeqToValue pr.output)
  ]

utest tomlToString (postResultToToml
{ app = { runtime = "runtime"
        , fileName = "fileName"
        , cwd = "cwd"
        , options = [{name = "name", contents = "contents"}]
        }
, output = ["output1", "output2"]
})
with
"
output = [\"output1\", \"output2\"]

[app]
cwd = \"cwd\"
fileName = \"fileName\"
runtime = \"runtime\"

[[app.options]]
contents = \"contents\"
name = \"name\"
"
using _strEqNoWhitespace


let resultToToml : Result -> TomlTable = lam r : Result.
  let binds =
    match r.ms_build with Some t then [("ms_build", tomlFloatToValue t)] else []
  in
  tomlFromBindings (concat binds
  [ ("input", tomlTableToValue (inputToToml r.input))
  , ("ms_run", tomlFloatSeqToValue r.ms_run)
  , ("command", tomlStringToValue r.command)
  , ("post", tomlTableSeqToValue (map postResultToToml r.post))
  ])


utest tomlToString (resultToToml
{ input = {file = Some "file.txt", data = Some "data", tags = [], cwd = "path/to"}
, ms_build = Some 0.1
, ms_run = [3.14, 5.6]
, post = [{ app = { runtime = "runtime"
                 , fileName = "fileName"
                 , cwd = "cwd"
                 , options = [{name = "name", contents = "contents"}]
                 }
         , output = ["output1", "output2"]}]
, command = "actual command"
})
with
"
command = \"actual command\"
ms_build = 0.1
ms_run = [3.14, 5.6]

[input]
cwd = \"path/to\"
data = \"data\"
file = \"file.txt\"
tags = []

[[post]]
output = [\"output1\", \"output2\"]

[post.app]
cwd = \"cwd\"
fileName = \"fileName\"
runtime = \"runtime\"

[[post.app.options]]
contents = \"contents\"
name = \"name\"
"
using _strEqNoWhitespace

let benchmarkResultToToml : BenchmarkResult -> TomlTable = lam r : BenchmarkResult.
  tomlFromBindings
  [ ("buildCommand", tomlStringToValue r.buildCommand)
  , ("results", tomlTableSeqToValue (map resultToToml r.results))
  , ("app", tomlTableToValue (appToToml r.app))
  ]

utest tomlToString (benchmarkResultToToml
{ buildCommand = "build command"
, app = { runtime = "runtime1", fileName = "fileName1", cwd = "cwd1"
        , options = [{name = "name1", contents = "contents1"}]}
, results =
  [{ input = {file = Some "file.txt", data = Some "data", tags = [], cwd = "path/to"}
   , ms_build = Some 0.1
   , ms_run = [3.14, 5.6]
   , post = [{ app = { runtime = "runtime"
                     , fileName = "fileName"
                     , cwd = "cwd"
                     , options = [{name = "name", contents = "contents"}]
                     }
            , output = ["output1", "output2"]}]
   , command = "actual command"
   }]
})
with
"
buildCommand = \"build command\"

[app]
cwd = \"cwd1\"
fileName = \"fileName1\"
runtime = \"runtime1\"

[[app.options]]
contents = \"contents1\"
name = \"name1\"

[[results]]
command = \"actual command\"
ms_build = 0.1
ms_run = [3.14, 5.6]

[results.input]
cwd = \"path/to\"
data = \"data\"
file = \"file.txt\"
tags = []

[[results.post]]
output = [\"output1\", \"output2\"]

[results.post.app]
cwd = \"cwd\"
fileName = \"fileName\"
runtime = \"runtime\"

[[results.post.app.options]]
contents = \"contents\"
name = \"name\"
"
using _strEqNoWhitespace

let collectedResultToToml : CollectedResult -> TomlTable = lam cr.
  tomlFromBindings [("benchmark", tomlTableSeqToValue (map benchmarkResultToToml cr))]

utest tomlToString (collectedResultToToml
[{ buildCommand = "build command"
 , app = { runtime = "runtime1", fileName = "fileName1", cwd = "cwd1"
         , options = [{name = "name1", contents = "contents1"}]}
 , results =
   [{ input = {file = Some "file.txt", data = Some "data", tags = [], cwd = "path/to"}
    , ms_build = Some 0.1
    , ms_run = [3.14, 5.6]
    , post = [{ app = { runtime = "runtime"
                      , fileName = "fileName"
                      , cwd = "cwd"
                      , options = [{name = "name", contents = "contents"}]
                      }
             , output = ["output1", "output2"]}]
    , command = "actual command"
    }]
 }])
with
"
[[benchmark]]
buildCommand = \"build command\"

[benchmark.app]
cwd = \"cwd1\"
fileName = \"fileName1\"
runtime = \"runtime1\"

[[benchmark.app.options]]
contents = \"contents1\"
name = \"name1\"

[[benchmark.results]]
command = \"actual command\"
ms_build = 0.1
ms_run = [3.14, 5.6]

[benchmark.results.input]
cwd = \"path/to\"
data = \"data\"
file = \"file.txt\"
tags = []

[[benchmark.results.post]]
output = [\"output1\", \"output2\"]

[benchmark.results.post.app]
cwd = \"cwd\"
fileName = \"fileName\"
runtime = \"runtime\"

[[benchmark.results.post.app.options]]
contents = \"contents\"
name = \"name\"
"
using _strEqNoWhitespace
