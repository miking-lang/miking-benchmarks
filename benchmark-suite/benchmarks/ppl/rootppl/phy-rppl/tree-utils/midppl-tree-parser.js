/**
 * File midppl-tree-parser.js converts a JSON tree into a format that can later
 * be used by the Miking DPPL compiler. The result is sent to standard output.
 */

const menu =
`Usage:
   node midppl-tree-parser.js treefile.phyjson rho

The output is written to the standard output. It should be directed to a file
named 'tree-instance.mc'.

Example:
   node midppl-tree-parser.js ../input-data/Alcedinidae.phyjson  0.5684210526315789
`

if(process.argv.length != 4){
    console.log(menu);
    process.exit(1);
}
const filename = process.argv[2];
const rho = process.argv[3];

const phyjs = require("../webppl/phyjs/index.js");
const tree = phyjs.read_phyjson(filename);

const pretty = (t) => {
    let age = Number.isInteger(t.age) ? t.age + ".0" : t.age
    if(t.type == 'node'){
        return "Node {left = " + pretty(t.left) +
            ", right = " + pretty(t.right) +
            ", age = " + age + "}";
    }
    else{
        return "Leaf {age = " + age + "}";
    }
}
console.log("-- This file was automatically generated based on the tree: " + filename + "\n");
console.log("include \"tree.mc\"\n");
console.log("let rho = " + rho + "\n");
console.log("let tree = " + pretty(tree))
