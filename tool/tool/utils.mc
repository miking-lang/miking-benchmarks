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

-- Replace all occurrences of substring 'old' in 'str' by substring 'new'.
let strReplace : String -> String -> String -> String =
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
