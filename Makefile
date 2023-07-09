TOOL_NAME=mi-bench
BIN_PATH=${HOME}/.local/bin

.PHONY: all install uninstall run run-test clean

all: build/${TOOL_NAME} build/toml-to-json

build/${TOOL_NAME}: $(shell find tool -name "*.mc")
	mi compile tool/main/${TOOL_NAME}.mc
	mkdir -p build
	cp ${TOOL_NAME} build/${TOOL_NAME}
	rm ${TOOL_NAME}

build/toml-to-json: toml-to-json/*
	$(CXX) -std=c++17 -o build/toml-to-json toml-to-json/prog.cpp

install: build/${TOOL_NAME}
	cp build/${TOOL_NAME} ${BIN_PATH}

uninstall:
	rm -f ${BIN_PATH}/${TOOL_NAME}

clean:
	rm -rf build
	rm -f output.toml

run: build/${TOOL_NAME}
	build/${TOOL_NAME} \
	--benchmarks benchmark-suite/benchmarks/mcore-ocaml \
	--runtimes benchmark-suite/runtimes \
	--iters 5 \
	--format toml \
	--log info \
	--warmups 1 > results.toml

run-ppl: build/${TOOL_NAME}
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters 2 \
		--format toml \
		--warmups 1

run-test: build/${TOOL_NAME}
	build/${TOOL_NAME} \
	--benchmarks benchmark-suite/test/benchmarks \
	--runtimes benchmark-suite/runtimes \
	--runtimes benchmark-suite/test/runtimes \
	--iters 5 \
	--format toml \
	--log info \
	--timeout-sec 1 \
	--warmups 1

test:
	mkdir -p build
	mi compile --test tool/tool/config-scanner.mc --output build/test; build/test
	mi compile --test tool/tool/runner.mc --output build/test; build/test
	mi compile --test tool/tool/utils.mc --output build/test; build/test
	mi compile --test tool/tool/path.mc --output build/test; build/test
	mi compile --test tool/tool/types.mc --output build/test; build/test


#################################################
## PPL experiments. Temporarily specified here ##
#################################################
number_iterations=15
number_warmups=1
prefix=A

experiment_example=example
run-experiment-example: build/${TOOL_NAME}
	find . -name $(experiment_example).toml.skip -execdir cp '{}' $(experiment_example).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl/phyl \
		--runtimes benchmark-suite/runtimes \
		--iters 1 \
		--format toml \
		--log info \
		--warmups 0
	cp output.toml output-example.toml
	find . -name $(experiment_example).toml -delete


experiment_crbd=experiment-CRBD
run-experiment-CRBD: build/${TOOL_NAME}
	find . -name $(experiment_crbd).toml.skip -execdir cp '{}' $(experiment_crbd).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl/phyl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--format toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-$(experiment_crbd).toml
	find . -name $(experiment_crbd).toml -delete

experiment_optimized_crbd=experiment-OptimizedCRBD
run-experiment-OptimizedCRBD: build/${TOOL_NAME}
	find . -name $(experiment_optimized_crbd).toml.skip -execdir cp '{}' $(experiment_optimized_crbd).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl/phyl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--format toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-OptimizedCRBD.toml
	find . -name $(experiment_optimized_crbd).toml -delete


run-experiment-ClaDS: build/${TOOL_NAME}
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl/phyl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--format toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-ClaDS.toml
	rm benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml

experiment_VBD=experiment-VBD
run-experiment-VBD: build/${TOOL_NAME}
	find . -name $(experiment_VBD).toml.skip -execdir cp '{}' $(experiment_VBD).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl/vbd \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--format toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-VBD.toml
	find . -name $(experiment_VBD).toml -delete

experiment_align=experiment-align
run-experiment-align: build/${TOOL_NAME} build/toml-to-json
	./run \
		--iters $(number_iterations) \
		--warmups $(number_warmups) \
		--name experiment-smc.toml
	mv output.toml $(experiment_align)-output.toml
	mv output.json $(experiment_align)-output.json


#################################################
## DAE experiments. Temporarily specified here ##
#################################################
number_iterations=15
number_warmups=1
prefix=A

run-dae: build/${TOOL_NAME}
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/dae \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--format toml \
		--log info \
		--warmups $(number_warmups) \
		--output ${prefix}-output-dae.toml
