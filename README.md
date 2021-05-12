# The Miking Benchmark Suite

The goal of this repository is to provide:

* A suite of benchmarks related to Miking.

* Tools to facilitate running, analyzing and reporting benchmark results.

## The Benchmark Suite

### Benchmarks

#### File Structure

Benchmarks are located in the `benchmarks` directory. Classes of benchmarks are
grouped together into subdirectories `benchmarks/<benchmark-class>`. Such a
subdirectory may in turn contain several benchmarks, and we refer to it as the
`root` of a class of benchmarks. For example, a suite of sorting benchmarks may
have `benchmarks/sort` as its `root`.

If the `root` contains several benchmarks, then they are each located in its
separate directory `root/<benchmark-name>` (further nesting is possible),
otherwise they may be placed directly in `root`. The `root` directory typically
contains a directory `root/datasets` containing datasets for the benchmarks in
`root`. If the class of benchmarks does not have any datasets, this directory
can be left out.

##### Example File Structure

The following shows an example directory structure for a suite of sorting
benchmarks; merge sort, insertion sort, and bucketsort implemented in `Java` and
`MCore`, respectively. The `.toml` files specify options for the benchmarks and
datasets, and are explained in [Configuration Files](#benchmark-configuration-files).

```
sort
├── datasets
│   ├── random1.txt
│   ├── reversed1.txt
│   └── sorted1.txt
├── insertsort
│   ├── java
│   ├── ├── config.toml
│   ├── └── insertsort.java
│   └── mcore
│       ├── config.toml
│       └── insertsort.mc
├── mergesort
│   ├── java
│   ├── ├── config.toml
│   ├── └── mergesort.java
│   └── mcore
│       ├── config.toml
│       └── mergesort.mc
├── bucketsort
│   ├── datasets
│   ├── ├── uniform1.txt
│   ├── └── nonuniform1.txt
│   ├── java
│   ├── ├── config.toml
│   ├── └── bucketsort.java
│   ├── mcore
│   │   ├── config.toml
│   │   └── bucketsort.mc
│   └── config.toml
├── config.toml
├── pre
│   └── pre.mc
├── post-1
│   └── post.mc
└── post-2
    └── post.py
```

#### Benchmark Configuration Files

Each benchmark needs to specify:
* A list `[[app]]` of applications to benchmark, with each list item consisting of
   * a `runtime`, e.g. what programming language the benchmark is written in,
   * an `argument` for specifying how to run the benchmark in its runtime,
   * an (optional) `options` for specifying command line options, and
   * an (optional) `buildOptions` for specifying command line build options,
   * an (optional) `base` for specifying where the application is built and run (default: the directory of the toml file),
* how `timing` of the benchmark is done,
* (optional) what preprocessing step `[pre]` (same internal structure as an
  `[[app]]`) should be run on all inputs,
* (optional) what postprocessing steps `[[post]]` (same internal structure as an
  `[[app]]`) should be run on all outputs, and
* (optional) a list of input data `[[input]]` that the benchmark should be run on, with each list item consisting of
   * a `file` or a `data` entry, specifying the path to the file containing the input data, or the immediate input data, respectively, and
   * a list `tags` (currently ignored).

The information is specified via `.toml` files. All `runtime`
fields must match a runtime specification in the `runtimes` directory (see
[Runtimes](#Runtimes)).

##### Example Benchmark Configuration File

The following is an example of what `sort/insertsort/mcore/config.toml` may look like for the `sort/insertsort/mcore/insertsort.mc`
benchmark in the [example file structure](#example-file-structure) above:

```toml
timing = "complete"    # Time the complete invocation of the benchmark (only supported option right now)

[[app]]
runtime = "MCore"
argument = "insertsort"    # Runs via 'mi insertsort.mc'
```

##### Hierarchical Configuration Files

Configuraton files can be specified hierarchically via the directory structure.
A benchmark will include all configuration files from all folders on its path.
This is often useful for sharing input data, a preprocessing step, and
postprocessing steps between benchmarks.

For example, `sort/config.toml` could look like
```toml
[pre]
runtime = "MCore"
argument = "pre"
base = "pre"

[[post]]
runtime = "MCore"
argument = "post"
base = "post-1"

[[post]]
runtime = "Python"
argument = "post"
options = "--some-important-option"
base = "post-2"

[[input]]
tags = ["random"]
file = "datasets/random1.txt"

[[input]]
tags = ["sorted"]
file = "datasets/sorted1.txt"

[[input]]
tags = ["reversed"]
file = "datasets/reversed1.txt"

[[input]]
tags = ["short"]
data = "[1,3,2]"
```
This configuration will be shared for all experiments under `sort` (including `sort/insertsort/mcore/insertsort.mc` from above).

### Runtimes

The `runtime` directory specifies a number of runtimes that benchmarks and
dataset programs can be run in. Each runtime is described by a single `.toml`
file. Multiple runtimes can provide support for the same language.

#### Runtime Configuration Files

A runtime configuration file specifies:

* What the runtime `provides` (typically, a programming language).
* A sequence of possible `command` entries for specifying how to run programs in
  the runtime. A `command` entry specifies:
  - A list of `required_executables` (optional).
  - A template `command`, where any occurrence of the string "{argument}" is to
    be replaced by the `argument` entry from in a benchmark or dataset
    configuration file.
  - A template `build_command` (optional): how to compile the benchmark. Again
  where "{argument}" is to be replaced.
  - A template `clean_command` (optional): how to clean up files after running
    the benchmark.
 
  
  The first command entry that has all required executables will be chosen.

The `runtime` directory contains several examples of runtime configuration
files.


## Running Benchmarks

A tool for running the benchmarks in this repository is under development. At
the very least, this tool will support:

* Running a specified subset of all benchmark and dataset combinations.
* Configuring settings such as runtime version of a language, number of
  iterations to run each benchmark and number of warmup runs.
* Saving the results in a format (yet to be decided) that can later be processed
  by the analyzing tool.

### Dependencies

The tool is implemented in MCore using Python FFI calls. It therefore requires
the Miking bootstrap interpreter, including the support of [Python
intrinsics](https://github.com/miking-lang/miking/tree/develop#python).

Moreover, the tool uses the following Python packages:

* `toml`

which can be installed using `pip`:

```bash
pip install toml
```


## Analyzing Benchmark Results

A tool to facilitate analyzing and reporting benchmark results is under
development. At the very least, this tool will support:

* Extracting statistical data such as mean values, standard deviations and
  statistical significance.
* Generating tables and plots of the results.


## MIT License

Copyright (c) 2020 David Broman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
