.PHONY: run test clean

run:
	cd tool && \
	mi main.mc -- \
	--benchmarks ../benchmark-suite/benchmarks \
	--runtimes ../benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--warmups 1

test:
	cd tool/test ; mi test .
	mi test tool/config-scanner.mc
	mi test tool/runner.mc
	mi test tool/toml.mc

clean:
	rm -rf benchmark-suite/benchmarks/ocaml-mcore-ocaml/fibonacci/ocaml/_build
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/fibonacci/ocaml2mcore2ocaml/fibonacci
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/fibonacci/ocaml2mcore2ocaml/fibonacci.mc

	rm -rf benchmark-suite/benchmarks/ocaml-mcore-ocaml/bstree/ocaml/_build
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/bstree/ocaml2mcore2ocaml/bstree
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/bstree/ocaml2mcore2ocaml/bstree.mc
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/bstree/mcore2ocaml/bstree

	rm -rf benchmark-suite/benchmarks/ocaml-mcore-ocaml/factorial/ocaml/_build
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/factorial/ocaml2mcore2ocaml/factorial
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/factorial/ocaml2mcore2ocaml/factorial.mc

	rm -rf benchmark-suite/benchmarks/ocaml-mcore-ocaml/sorting/ocaml/_build
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/sorting/mcore2ocaml/quick_sort
