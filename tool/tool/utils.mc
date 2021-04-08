include "string.mc"

-- Check if 'str' starts with 'prefix'
let startsWith = lam prefix. lam str.
  isPrefix eqChar prefix str

utest startsWith "" "xyz" with true
utest startsWith "_" "_build" with true
utest startsWith "A" "abc" with false

-- Check if 'str' ends with 'suffix'
let endsWith = lam str. lam suffix.
  isSuffix eqChar suffix str

utest endsWith "abc" "" with true
utest endsWith "abc" "bc" with true
utest endsWith "abc" "bbc" with false

-- Trim 's' such that it does no longer have 'prefix' as prefix.
recursive let trimPrefix = lam prefix. lam s.
  match prefix with "" then
    error "The empty string is always a prefix"
  else if startsWith prefix s then
    let n = length prefix in
    match splitAt s n with (_, s) then
      trimPrefix prefix s
    else never
  else s
end

utest trimPrefix "H" "HHHHello" with "ello"
utest trimPrefix "a" "ABC" with "ABC"

-- Replace all occurrences of substring 'old' in 'str' by substring 'new'.
let strReplace : String -> String -> String =
  lam str. lam old. lam new.
    let oldLen = length old in
    recursive let work = lam str.
      match str with "" then str
      else
        if startsWith old str then
          match splitAt str oldLen with (_, str) then
            concat new (work str)
          else never
        else cons (head str) (work (tail str))
    in work str

utest strReplace "Hello" "H" "Y" with "Yello"
utest strReplace "" "H" "Y" with ""
utest strReplace "./{argument} -- {argument}" "{argument}" "prog"
with "./prog -- prog"

let mean : [Float] -> Float = lam data.
  match data with [] then error "Mean of empty sequence" else
  divf (foldl1 addf data) (int2float (length data))

utest mean [1.0] with 1.0
utest mean [1., 0.0, 41.0] with 14.0
