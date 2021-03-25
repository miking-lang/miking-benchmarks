run:
	cd tool && \
	mi main.mc -- \
	--benchmarks ../benchmark-suite/benchmarks \
	--runtimes ../benchmark-suite/runtimes \
	--iters 5 \
	--warmups 1

test:
	cd tool/test ; mi test .
	mi test tool/config-scanner.mc
	mi test tool/runner.mc

clean:
	rm -rf benchmark-suite/benchmarks/ocaml-mcore-ocaml/fibonacci/ocaml/_build
	rm -f benchmark-suite/benchmarks/ocaml-mcore-ocaml/fibonacci/ocaml2mcore2ocaml/prog
