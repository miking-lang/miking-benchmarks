/**
 * File midppl-tree-parser.js converts a JSON tree into format that can later
 * be used by the Miking DPPL compiler. The result is sent to standard output.
 *
 * Usage:
 *  node midppl-tree-parser.js treefile.phyjson
 *
 * The output is written on the standard output.
 *
 * Example:
 *  node midppl-tree-parser.js ../input-data/Alcedinidae.phyjson > tree.mc
 */

const phyjs = require("../webppl/phyjs/index.js");

var tree = phyjs.read_phyjson(process.argv[2]);

console.log(tree)
