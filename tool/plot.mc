
type PlotOptions =
{ legend : Bool
, grid : Bool
, xmin : Option Float
, xmax : Option Float
, ymin : Option Float
, ymax : Option Float
}

let _blt = pyimport "builtins"
let _plt = pyimport "matplotlib.pyplot"


let _markers =
[ "." 	-- point
--, "," 	-- pixel        -- Tiny
, "o" 	-- circle
, "v" 	-- triangle_down
, "^" 	-- triangle_up
, "<" 	-- triangle_left
, ">" 	-- triangle_right
, "1" 	-- tri_down
, "2" 	-- tri_up
, "3" 	-- tri_left
, "4" 	-- tri_right
, "8" 	-- octagon
, "s" 	-- square
, "p" 	-- pentagon
, "P" 	-- plus (filled)
, "*" 	-- star
, "h" 	-- hexagon1
, "H" 	-- hexagon2
, "+" 	-- plus
, "x" 	-- x
, "X" 	-- x (filled)
, "D" 	-- diamond
, "d" 	-- thin_diamond
]
let _markerIdx = ref 0

let _markerGetNext = lam.
  let i = deref _markerIdx in
  modref _markerIdx (modi (addi i 1) (length _markers));
  get _markers i

let _markerClear = lam. modref _markerIdx 0

let plotDefaultOptions =
{ legend = true
, grid = true
, xmin = Some 0
, xmax = None () -- Let Python set the max value
, ymin = Some 0.0
, ymax = None ()
}

let plotAddPlot =
  lam label : String.
  lam x : [Int].
  lam y : [Float].
  lam xticks : [String].
    pycallkw _plt "plot" (x, y) {label= label, marker= _markerGetNext ()};
    pycallkw _plt "xticks" (x, xticks) {rotation = 45};
    pycall _plt "tight_layout" ();
    ()

let plotFinalizePlot = lam ops : PlotOptions. lam name : String.
  (if ops.legend then pycall _plt "legend" () else ());

  (if ops.grid then
     pycallkw _plt "grid" () {axis = "both", linestyle = "--"}
   else ());

  (match ops.xmin with Some v then
     pycallkw _plt "xlim" () {xmin = v}
   else ());

  (match ops.xmax with Some v then
     pycallkw _plt "xlim" () {xmax = v}
   else ());

  (match ops.ymin with Some v then
     pycallkw _plt "ylim" () {ymin = v}
   else ());

  (match ops.ymax with Some v then
     pycallkw _plt "ylim" () {ymax = v}
   else ());

  pycall _plt "savefig" (concat name ".png",);

  _markerClear ();
  pycall _plt "clf" ()
