.PHONY: run plot test

run:
	boot eval tool/main/main.mc -- \
	--benchmarks benchmark-suite/benchmarks/mcore-ocaml \
	--runtimes benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--warmups 1 > results.toml

run-ppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 50 \
	  --output toml \
	  --warmups 1


run-test-ppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 1 \
	  --output toml \
	  --warmups 1


run-webppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/webppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 1 \
	  --output toml \
	  --warmups 1


run-rootppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/rootppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 100 \
	  --output toml \
	  --warmups 1

run-midppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/midppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 1 \
	  --output toml \
	  --warmups 1


run-birch:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/birch \
	  --runtimes benchmark-suite/runtimes \
	  --iters 1 \
	  --output toml \
	  --warmups 1

run-pyro:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/pyro \
	  --runtimes benchmark-suite/runtimes \
	  --iters 3 \
	  --output toml \
	  --warmups 1

run-pyro-numpy:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/pyro+numpy \
	  --runtimes benchmark-suite/runtimes \
	  --iters 3 \
	  --output toml \
	  --warmups 1

run-pyro-numba:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/pyro+numba \
	  --runtimes benchmark-suite/runtimes \
	  --iters 3 \
	  --output toml \
	  --warmups 1

run-test:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/test/benchmarks \
	  --runtimes benchmark-suite/runtimes \
	  --iters 5 \
	  --output toml \
	  --warmups 1

plot:
	boot eval tool/main/main.mc -- \
	--benchmarks benchmark-suite/benchmarks \
	--plot results.toml \
	&& convert *.png report.pdf

test:
	boot eval --test tool/tool
