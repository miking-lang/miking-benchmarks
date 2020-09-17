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
datasets, and are explained in [Benchmark Configuration
Files](#benchmark-configuration-files) and [Dataset Configuration
Files](dataset-configuration-files), respectively.

```
sort
├── datasets
│   ├── datasets.toml
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
└── bucketsort
    ├── datasets
    ├── ├── datasets.toml
    ├── ├── uniform1.txt
    ├── └── nonuniform1.txt
    ├── java
    ├── ├── config.toml
    ├── └── bucketsort.java
    └── mcore
        ├── config.toml
        └── bucketsort.mc

```

#### Benchmark Configuration Files

Each benchmark needs to specify:
* `runtime`, e.g. what programming language the benchmark is written in,
* `argument` for specifying how to run the benchmark in its runtime,
* how `timing` of the benchmark is done, and
* optionally: a list `additional-datasets` of directories of datasets to use in
  addition to the implicit ones. Implicit datasets are placed in `datasets`
  directories, see [Implicit Datasets](#implicit-datasets) for more information.

The information is specified via `.toml` files. The `runtime` and `argument`
fields must match a runtime specification in the `runtimes` directory (see
[Runtimes](#Runtimes)).

##### Example Benchmark Configuration File

The following may be a specification for the `sort/insertsort/insertsort.mc`
benchmark in the [example file structure](#example-file-structure) above:

```toml
runtime = "MCore"
argument = "insertsort"    # Runs via 'mi insertsort.mc'
timing = "complete"    # Time the complete invocation of the benchmark (only supported option right now)
```

This benchmark uses no datasets except the ones in `sort/datasets`, and there is
therefore no need to use the `additional-dataset` option. If there had been some
other directory with datasets, for example in `../shared-data/lists`, then the
following specifies that `insertsort.mc` should additionally use that dataset:

```toml
additional-datasets = ['../shared-data/lists']    # Relative path from the config file
```

##### Hierarchical Dataset Specification

Datasets can be specified hierarchically via the directory structure. A
benchmark will include all datasets from all folders named `datasets` present in
its current file path (starting in the benchmark's `root`). This is useful, for
example, when some benchmarks require specialized datasets.
 
##### Example Hierarchical Dataset Specification

In the [example file structure](#example-file-structure), the `bucketsort`
directory includes a `datasets` directory. This means that `bucketsort.java` and
`bucketsort.mc` will use datasets from both `sort/datasets` and
`sort/bucketsort/datasets`.


### Datasets

A dataset, typically placed in a `datasets` directory, is a program that is to
be run before the benchmark using the dataset is run. The standard output of the
dataset program will be piped into the benchmark command after the dataset
program has terminated.

#### Implicit Datasets

Datasets specified in a directory named `datasets` become implicit and
compulsory for all the benchmarks specified at the same level or below in the
file directory structure. That is, neither do the benchmarks have to specify
that they use these datasets, nor can they opt out from using them. Therefore,
such datasets need to be compatible with all its related benchmarks. See
[Hierarchical Dataset Specification](#hierarchical-dataset-specification) for
how implicit datasets are collected along the file path.

As described in [Benchmark Configuration Files](#benchmark-configuration-files),
benchmarks can also explicitly state which datasets to use; such datasets can be
placed in any directory.

#### Dataset Configuration Files

A dataset configuration file specifies:
* A `runtime` in which to run the benchmark program (see [Benchmark
  Configuration Files](#benchmark-configuration-files)).
* A sequence of `dataset` entries, one for each dataset program, having an
  `argument` field (see [Benchmark Configuration
  Files](#benchmark-configuration-files)) and, optionally, a list of `tags`
  describing the dataset entry.

##### Example of a Dataset Configuration File

The `sort/datasets/datasets/config.toml` from the [example file
structure](#example-file-structure) may look like this:

```toml
runtime = "text"    # must match 'provides' in a runtime

[[dataset]]
tags = ["random"]
argument = "random1.txt"

[[dataset]]
tags = ["sorted"]
argument = "sorted1.txt"

[[dataset]]
tags = ["reversed"]
argument = "reversed1.txt"
```

Here we assume `text` is a runtime for printing the contents of a file, e.g.
`cat` on a Unix system.

### Runtimes

The `runtime` directory specifies a number of runtimes that benchmarks and
dataset programs can be run in. Each runtime is described by a single `.toml`
file. Multiple runtimes can provide support for the same language.

#### Runtime Configuration Files

A runtime configuration file specifies:

* What the runtime `provides` (typically, a programming language).
* A sequence of possible `command` entries for specifying how to run programs in
  the runtime. A `command` entry specifies:
  - A list of `required-executables` (optional).
  - A template `command`, where any occurrence of the string "{argument}" is to
    be replaced by the `argument` entry from in a benchmark or dataset
    configuration file.
  - A template `build-command` (optional): how to compile the benchmark. Again
  where "{argument}" is to be replaced.
  
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
