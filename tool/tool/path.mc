include "string.mc"
include "utils.mc"
include "python/python.mc"

type Path = String

let _blt = pyimport "builtins"
let _os = pyimport "os"
let _os_path = pythonGetAttr _os "path"
let _shutil = pyimport "shutil"

-- Check if a path exists
let pathExists : Path -> Bool = lam path.
  pyconvert (pycall _os_path "exists" (path,))

utest pathExists "." with true

-- Check if path is a command
let pathIsCmd = lam path.
  match pyconvert (pycall _shutil "which" (path,))
  with "" then false else true

let pathConcat : Path -> Path -> Path = lam p1. lam p2.
  join [p1, "/", p2]

utest pathConcat "/path/to" "hello" with "/path/to/hello"

-- Get the path of 'path' relative to 'start'
let pathRel = lam path. lam start.
  pyconvert (pycallkw _os_path "relpath" (path,) {start = start})

utest pathRel "." "" with "."
utest pathRel "." "." with "."
utest pathRel ".." "" with ".."
utest pathRel ".." "." with ".."

-- Get the absolute path of 'path' (could be relative or absolute)
let pathAbs = lam path.
  pyconvert (pycall _os_path "abspath" (path,))

-- Format path into a string using 'delim' as delimiter instead of the usual
-- path separator
let pathWithDelim = lam path. lam delim.
  let sep = pyconvert (pythonGetAttr _os_path "sep") in
  strReplace path sep delim

utest pathWithDelim "" "xyz" with ""
utest pathWithDelim "path/to/something" "::" with "path::to::something"

-- Get all the files and sub-directories immediately below a directory
let pathList : Path -> {dirs : [Path], files : [Path]} = lam dir.
  if pathExists dir then
    let walk = pycall _blt "list" (pycall _os "walk" (dir,),) in
    let lst = pyconvert walk in
    match lst with [] then
      {dirs = [], files = []}
    else match lst with [top] ++ _ then
      {dirs = top.1, files = top.2}
    else never
  else error (concat "No such directory: " dir)

-- Traverse through the directory tree, starting at 'root' and with accumulator
-- 'acc', accumulating a value by applying 'f' on each file in the tree. Only
-- considers directories for which 'pDir' is true.
recursive let pathFold =
  lam pDir : Path -> Bool.
  lam f : (a -> Path -> a).
  lam acc : a.
  lam root : Path.
    let ls = pathList root in
    let files = map (pathConcat root) ls.files in
    let dirs = map (pathConcat root) (filter pDir ls.dirs) in
    let acc = foldl f acc files in
    foldl
      (lam a. lam dir. pathFold pDir f a dir)
      acc dirs
end

-- Similar to 'pathFoldWD', but folds over directories rather than files. Also,
-- see description for pathFoldWD below.
recursive let pathFoldDirWD =
  lam pDir : Path -> Bool.
  lam f : ((a, b) -> [Path] -> (a, b)).
  lam accW : a.
  lam accD : b.
  lam root : Path.
    let ls = pathList root in
    let files = map (pathConcat root) ls.files in
    let dirs = map (pathConcat root) (filter pDir ls.dirs) in
    match f (accW, accD) files with (accW, accD) then
      foldl (lam accD. lam dir.
          pathFoldDirWD pDir f accW accD dir
        ) accD dirs
    else never
end

-- Similar to 'pathFold', but only 'accD' is accumulated for all files, while
-- 'accW' is accumulated path-wise in the tree.
recursive let pathFoldWD =
  lam pDir. lam f. pathFoldDirWD pDir (lam acc. lam dirs. foldl f acc)
end

-- Get the parent directory in which 'file' resides
let pathGetParent = lam file.
  match strLastIndex '/' file with Some idx then
    subsequence file 0 idx
  else "."

utest pathGetParent "hello.txt" with "."
utest pathGetParent "/path/to/hello.txt" with "/path/to"
