number_iterations=15
number_warmups=1
prefix=A

TOOL_NAME=mi-bench
BIN_PATH=${HOME}/.local/bin

.PHONY: all install run run-test clean

all:
	mi compile tool/main/${TOOL_NAME}.mc
	mkdir -p build
	cp mi-bench build/${TOOL_NAME}
	rm ${TOOL_NAME}

install: all
	cp build/${TOOL_NAME} ${BIN_PATH}

clean:
	rm -rf build
	rm -f output.toml

run: all
	build/${TOOL_NAME} \
	--benchmarks benchmark-suite/benchmarks/mcore-ocaml \
	--runtimes benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--log info \
	--warmups 1 > results.toml

run-ppl: all
	build/${TOOL_NAME} \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1

run-test: all
	build/${TOOL_NAME} \
	--benchmarks benchmark-suite/test/benchmarks \
	--runtimes benchmark-suite/runtimes \
	--runtimes benchmark-suite/test/runtimes \
	--iters 5 \
	--output toml \
	--log info \
	--timeout-s 1 \
	--warmups 1

test:
	mi compile --test tool/tool/config-scanner.mc; ./config-scanner
	mi compile --test tool/tool/runner.mc; ./runner
	mi compile --test tool/tool/utils.mc; ./utils
	mi compile --test tool/tool/path.mc; ./path
	mi compile --test tool/tool/data.mc; ./data

run-experiment-CRBD: all
	cp benchmark-suite/benchmarks/ppl/birch/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/birch/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/midppl/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/midppl/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/pyro+numba/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/pyro+numba/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/pyro+numpy/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/pyro+numpy/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-CRBD.toml
	cp benchmark-suite/benchmarks/ppl/webppl/experiment-CRBD.toml.skip benchmark-suite/benchmarks/ppl/webppl/experiment-CRBD.toml
	build/${TOOL_NAME} \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters $(number_iterations) \
	  --output toml \
	  --warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-CRBD.toml
	rm benchmark-suite/benchmarks/ppl/birch/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/midppl/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/pyro+numba/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/pyro+numpy/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/rootppl/experiment-CRBD.toml benchmark-suite/benchmarks/ppl/webppl/experiment-CRBD.toml


run-experiment-OptimizedCRBD: all
	cp benchmark-suite/benchmarks/ppl/birch/experiment-OptimizedCRBD.toml.skip benchmark-suite/benchmarks/ppl/birch/experiment-OptimizedCRBD.toml
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-OptimizedCRBD.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-OptimizedCRBD.toml
	cp benchmark-suite/benchmarks/ppl/pyro+numba/experiment-OptimizedCRBD.toml.skip benchmark-suite/benchmarks/ppl/pyro+numba/experiment-OptimizedCRBD.toml
	build/${TOOL_NAME} \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters $(number_iterations) \
	  --output toml \
	  --warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-OptimizedCRBD.toml
	rm benchmark-suite/benchmarks/ppl/birch/experiment-OptimizedCRBD.toml benchmark-suite/benchmarks/ppl/rootppl/experiment-OptimizedCRBD.toml benchmark-suite/benchmarks/ppl/pyro+numba/experiment-OptimizedCRBD.toml
