/**
 * @file JS script to compile and run a WebPPL file.
 *
* SYNOPSIS:
*
* npm run wppl SCRIPT [n] [-- batch]
*
* DESCRIPTION
*
* Runs the WebPPL SCRIPT specified by the script, n number of times. It has two
* modes of operation: online (default) and batch mode (specified by the optional
* argument `-- batch`, note the space). If you run in online mode the ouput
* of SCRIPT is printed to standard output n times (default 1 if omitted). If running
* in batch mode, the output is stored in the `runs` directory, with the name
* constructed from SCRIPT.
* 
* NOTE
* 
* 1. When specifying directories under DOS/Windows, please use // as a separator
* and not a single slash.
* 
* 2. If you run in batch mode, we recommend increasing the loglevel by renaming
* the hidden file `.npmrc` to `npmrc`
 *
 */

// constants
const MAX_ITERATIONS = 64
const DEFAULT_ITERATIONS = 1
const DEFAULT_TREE = "src/bisse_32.phyjson"
const DEFAULT_RHO = 1.0
const DEFAULT_NPART = 5000
require('events').EventEmitter.defaultMaxListeners = MAX_ITERATIONS;


// Variables
var phylomodels // the model package directory
var phylodata   // JS package directory
var webppl      // the webppl script to be executed
var js          // intermediate javascript directory
var stacksize   // the stacksize to be passed to the node executable
var iterations  // the number of iterations to be run
var executable  // the name of the javascript executable after compilation
var treefile    // filename storing the path to the tree
var rho         // sampling fraction
var particles   // number of particles

      
// Error handling
const errors = ["No WebPPL script provided.\nSYNOPSIS\nnpm run wppl SCRIPT [n]\n",
		"Missing or invalid iteration number, defaulting to ".concat(DEFAULT_ITERATIONS).concat(". MAX is ").concat(MAX_ITERATIONS).concat(".\n"),
	  "On Windows, please use double backslash \\\\ to give the full name of the WebPPL script you want to execute, as a single backslash \\ is a meta-syntactic character (escape character) in JavaScript.\n",
		"Failure to produce a meaningful result while running a WebPPL file.\n",
		"Defaulting tree and rho and nparts.\n",
		"Defaulting rho and nparts.\n",
	        "Defaulting nparts.\n"]
const error_types = ["Error", "Warning"]

/**
 * Simple error funciton
 * Prints an error or a warning
 * @param error_code the error code (integer)
 * @param type the error type (integer)
 */
const output_error = function(error_code, type) {
    console.error(error_types[type] + " " + error_code + ": " + errors[error_code])
}


// Setting the directories
phylomodels = process.cwd() // asuming that we are calling npm run from the package root
phylodata = phylomodels.concat("/node_modules/phyjs")
js = phylomodels.concat("/js")


// Setting paramters from command line arguments
// 0 : the node executable
// 1 : the script that is running (this script)
// 2 : the stacksize
// 3 : the webppl script that needs to be run
// 4 : iteration number (optional)
// 5 : tree path (optional)
// 6 : sampling fraction rho (optional)
// 7 : number of particles (optional)
stacksize = process.argv[2]
if (process.argv.length < 4) {
    output_error(0, 0)
    return false
} else if (process.argv.length == 4) {
    webppl = process.argv[3]
    output_error(1, 1)
    iterations = DEFAULT_ITERATIONS
    treefile = DEFAULT_TREE 
    rho = DEFAULT_RHO
    particles = DEFAULT_NPART
} else if (process.argv.length == 5) {
    webppl = process.argv[3]
    iterations = process.argv[4]
    output_error(4, 1)
    treefile = DEFAULT_TREE
    rho = DEFAULT_RHO
    particles = DEFAULT_NPART
} else if (process.argv.length == 6) {
    webppl = process.argv[3]
    iterations = process.argv[4]
    treefile = process.argv[5]
    output_error(5, 1)
    rho = DEFAULT_RHO
    particles = DEFAULT_NPART
} else if (process.argv.length == 7) {
    webppl = process.argv[3]
    iterations = process.argv[4]
    treefile = process.argv[5]
    rho = process.argv[6]
    particles = DEFAULT_NPART
}
else if (process.argv.length == 8) {
    webppl = process.argv[3]
    iterations = process.argv[4]
    treefile = process.argv[5]
    rho = process.argv[6]
    particles = process.argv[7]
}
				    

// check
if (isNaN(iterations) || iterations < 1 || iterations > MAX_ITERATIONS) {
    output_error(1, 1)
    iterations = DEFAULT_ITERATIONS
}

// The name of the JS executable
// It's the same as the example name
var path = require('path')
var file = path.parse(webppl)
if (process.platform == "win32") {
    output_error(2,1)
}

executable = file.dir.replace(/[\/\\]/g, "_" ) + "_" + file.name + ".js"


// Compilation
// TODO test windows
var shell = require('shelljs')
var compile_command
if (process.platform == "win32") {
    compile_command = "webppl " + webppl + " --require " + phylomodels + " --require " + phylodata + " --compile --out " + js + "/" + executable +  "> nul "
}
else {
    compile_command = "webppl " + webppl + " --require " + phylomodels + " --require " + phylodata + " --compile --out " + js + "/" + executable + " 1>/dev/null"
}
shell.config.silent = true;
shell.rm(js + "/" + executable)
shell.config.silent = false;
shell.exec(compile_command)



//Execution
// exec_command = "node " + " --stack-size=" +   stacksize + " " + " --max-old-space-size=4096 " + js + "/" + executable + " " + treefile + " " + rho + " " + particles
// console.log(exec_command)

// for (i = 0; i < iterations; i++) {
//     shell.exec(exec_command, {async:true} )
// }



