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
	  --iters 2 \
	  --output toml \
	  --warmups 1

run-webppl:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/webppl/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/webppl/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/webppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/webppl/example.toml

run-rootppl:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/rootppl/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/rootppl/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/rootppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm  /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/rootppl/example.toml

run-midppl:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/midppl/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/midppl/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/midppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/midppl/example.toml

run-birch:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/birch/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/birch/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/birch \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/birch/example.toml

run-pyro:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/pyro \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro/example.toml

run-pyro-numpy:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro-numpy/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro-numpy/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/pyro+numpy \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro-numpy/example.toml	  

run-pyro-numba:
	cp /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro-numba/example.toml.skip /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro-numba/example.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl/pyro+numba \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1
	rm /home/viktor/ownCloud/miking-benchmarks/benchmark-suite/benchmarks/ppl/pyro-numba/example.toml

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

run-experiment-CRBD:
	cp benchmark-suite/benchmarks/ppl/birch/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/birch/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/midppl/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/midppl/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/pyro+numba/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/pyro+numba/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/pyro+numpy/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/pyro+numpy/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/webppl/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/webppl/experiment-CRBD.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 100 \
	  --output toml \
	  --warmups 1
	rm benchmark-suite/benchmarks/ppl/birch/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/midppl/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/pyro+numba/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/pyro+numpy/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/rootppl/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/webppl/experiment-CRBD.toml


run-experiment-OptimizedCRBD:
	cp benchmark-suite/benchmarks/ppl/birch/experiment-OptimizedCRBD.toml.skip benchmark-suite/benchmarks/ppl/birch/experiment-OptimizedCRBD.toml
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-OptimizedCRBD.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-OptimizedCRBD.toml
	cp benchmark-suite/benchmarks/ppl/pyro+numba/experiment-OptimizedCRBD.toml.skip benchmark-suite/benchmarks/ppl/pyro+numba/experiment-OptimizedCRBD.toml
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 100 \
	  --output toml \
	  --warmups 1
	rm benchmark-suite/benchmarks/ppl/birch/experiment-OptimizedCRBD.toml benchmark-suite/benchmarks/ppl/rootppl/experiment-OptimizedCRBD.toml benchmark-suite/benchmarks/ppl/pyro+numba/experiment-OptimizedCRBD.toml
