include "string.mc"
include "python/python.mc"

type Path = String

-- Check if a path exists
let pathExists : Path -> Bool = lam path.
  let oslib = pyimport "os" in
  pyconvert (pycall (pythonGetAttr oslib "path") "exists" (path,))

utest pathExists "." with true

let pathConcat : Path -> Path -> Path = lam p1. lam p2.
  join [p1, "/", p2]

utest pathConcat "/path/to" "hello" with "/path/to/hello"

-- Get all the files and sub-directories immediately below a directory
let pathList : Path -> {dirs : [Path], files : [Path]} = lam dir.
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
    foldl (lam acc. lam dir. pathFold pDir f acc dir) acc dirs
end

-- Get the parent directory in which 'file' resides
let pathGetParent = lam file.
  match strLastIndex '/' file with Some idx then
    subsequence file 0 idx
  else "."

utest pathGetParent "hello.txt" with "."
utest pathGetParent "/path/to/hello.txt" with "/path/to"
