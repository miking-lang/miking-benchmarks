
include "sys.mc"
include "common.mc"

type Path = String

let pathExists : Path -> Bool = lam path.
  match sysRunCommand ["ls", path] "" "." with {returncode = 0} then true
  else false

utest pathExists "." with true

-- Check if path is a command
let pathIsCmd = lam path. sysCommandExists path

utest pathIsCmd "ls" with true

-- Concatenate two paths
let pathConcat : Path -> Path -> Path = lam p1. lam p2.
  join [p1, "/", p2]

utest pathConcat "/path/to" "hello" with "/path/to/hello"

-- Get the absolute path of 'path' (could be relative or absolute)
let pathAbs = lam path.
  match sysRunCommand ["pwd"] "" path with {stdout = stdout} then strTrim stdout
  else never

--utest pathAbs "." with ""

-- Get all the files and sub-directories immediately below a directory
let pathList : Path -> {dirs : [Path], files : [Path]} = lam dir.
  if pathExists dir then
    let files =
      match sysRunCommand ["find", ".", "-maxdepth", "1", "-type", "f"] "" dir
      with {stdout = stdout} then
      strSplit "\n" (strTrim stdout)
      else never
    in
    let dirs =
      match sysRunCommand ["find", ".", "-maxdepth", "1", "-type", "d"] "" dir
      with {stdout = stdout} then
        let allDirs = strSplit "\n" (strTrim stdout) in
        filter (lam d. not (eqString "." d)) allDirs
      else never
    in
    {files = files, dirs = dirs}
  else error (concat "No such directory: " dir)

-- utest pathList "." with {files = [], dirs = []}

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
let pathGetParent = lam path.
  match strLastIndex '/' path with Some idx then
    subsequence path 0 idx
  else "."

utest pathGetParent "hello.txt" with "."
utest pathGetParent "/path/to/hello.txt" with "/path/to"

-- Get the file name from a path
let pathGetFile = lam path: String.
  match strLastIndex '/' path with Some idx then
    subsequence path (addi idx 1) (subi (length path) 1)
  else path

utest pathGetFile "hello.txt" with "hello.txt"
utest pathGetFile "/path/to/hello.txt" with "hello.txt"
utest pathGetFile "/path/to/" with ""
