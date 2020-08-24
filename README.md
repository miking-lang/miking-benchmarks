# The Miking Benchmark Suite

The goal of this repository is to provide:

* A suite of benchmarks related to Miking.

* Tools to facilitate running, analyzing and reporting benchmark results.

## The Benchmark Suite

### Benchmarks

#### File Structure

Benchmarks are located in the `benchmarks` directory. Classes of benchmarks are
grouped into subdirectories `benchmarks/<benchmark-class>`. Such a subdirectory
may in turn contain several benchmarks, and we refer to it as the `root` of a
class of benchmarks. For example, a suite of sorting benchmarks may have
`benchmarks/sort` as its `root`.

If the `root` contains several benchmarks, then they are each located in its
separate directory `root/<benchmark-name>` (further nesting is possible),
otherwise they may be placed directly in `root`. The `root` directory typically
contains a directory `root/datasets` containing datasets for the benchmarks in
`root`. If the benchmark class does not have datasets, this directory can be
left out.

##### Example File Structure

The following shows an example directory structure for a suite of
four sorting benchmarks; merge sort and insertion sort in `Java` and `MCore`,
respectively (for now, the `.toml` configuration  files may be ignored):
```
sort
├── datasets.toml
├── datasets
│   ├── config.toml
│   ├── random1.txt
│   ├── reversed1.txt
│   └── sorted1.txt
├── java
│   ├── config.toml
│   ├── insertion-sort
│   │   ├── config.toml
│   │   └── insertion-sort.java
│   └── merge-sort
│       ├── config.toml
│       └── merge-sort.java
└── mcore
    ├── insertion-sort
    │   ├── config.toml
    │   └── insertion-sort.mc
    └── merge-sort
        ├── config.toml
        └── merge-sort.mc
```

#### Benchmark Configuration Files

Each benchmark needs to specify:
* `runtime`, e.g. programming language,
* `argument` for specifying how to run the benchmark in its runtime,
* how `timing` of the benchmark is done, and
* optionally: a list of directories with `dataset`s for the benchmark.

The information is specified via `.toml` files. The `runtime` and `argument`
fields must match a runtime specification in the `runtimes` directory (see
[Runtimes](#Runtimes)).

##### Example Benchmark Configuation File

The following may be a specification for the
`sort/mcore/insertion-sort/insertion-sort.mc` benchmark in the
[example](#example-file-structure) above:

```[toml]
runtime = "MCore"
argument = "insertion-sort"    # Runs via 'mi insertion-sort.mc'
timing = "simple"    # Only supported option right now
dataset = ["datasets"]    # Relative path from 'root' of benchmark
```

##### Flat vs. Nested Configurations

Since many of the benchmarks in the same `root` directory may be configured in
similar ways (e.g. use the same datasets), it is possible to "inherit"
configurations via the directory structure. That is, the configuration of a
benchmark is the union of the configurations of the `.toml` files present in the
file path from the `root` directory to the benchmark directory. The "union"
operator does *not* allow overwriting of configurations and any implementation
of the configuration protocol should return an error if `runtime`, `argument`,
or `timing` is specified twice. In contrast, the `dataset` configuration *is*
allowed to be specified several times, the resulting set of datasets being the
*union* of all the specified datasets.

##### Example of a Nested Benchmarking Configuration

The [example file structure](#example-file-structure) may have a common `.toml`
file `sort/datasets.toml` for specifying that all benchmarks in the `sort`
directory may use data from the `sort/datasets` directory:

```[toml]
dataset = ["datasets"]
```

Next, the configuration file `sort/mcore/config.toml` specifies the runtime and
timing option common for all the benchmarks in the `sort/mcore` directory:

```[toml]
runtime = "Java"
timing = "simple"
```

Last, the `sort/mcore/insertion-sort/config.toml` file specifies how to run a
specific benchmark:

```[toml]
argument = "insertion-sort"
```

This nested way of configuring the benchmark
`sort/mcore/insertion-sort/insertion-sort.mc` is equivalent to, but less
redundant than, the flat version in [the previous
example](#example-benchmark-configuration-file).

### Datasets

A dataset, typically placed in a `benchmarks/<benchmark-class>/datasets`
directory, is a program that will be run before the benchmark using the
dataset is run. The standard output of the dataset program will be piped into
the benchmark command after the dataset program has terminated.

#### Dataset Configuration Files

A dataset configuration file specifies:
* A `runtime` in which to run the benchmark program (see [Benchmark
  Configuration Files](#benchmark-configuration-files)).
* A sequence of `dataset` entries, one for each dataset program, having an
  `argument` field (see [Benchmark Configuration
  Files](#benchmark-configuration-files)) and, optionally, a list of `tags`
  describing the dataset entry.

Unlike for benchmark configuration, dataset configuration may not be nested.

##### Example of a Dataset Configuration File

The `sort/datasets/datasets/config.toml` from the [example file
structure](#example-file-structure) may look like this:

```[toml]
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

Here we assume `text` is a runtime for printing the content of a file, i.e.
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
  - A template `command`, where any occurrence of the string "{argument}" is
    replaced by what was specified in a benchmark of dataset configuration file.
  - A template `build-command` (optional), again where "{argument}" is to be replaced.
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
