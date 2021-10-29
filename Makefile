TOOL_NAME=mi-bench
BIN_PATH=${HOME}/.local/bin

.PHONY: all install uninstall run run-test clean

all:
	mi compile tool/main/${TOOL_NAME}.mc
	mkdir -p build
	cp ${TOOL_NAME} build/${TOOL_NAME}
	rm ${TOOL_NAME}

install:
	cp build/${TOOL_NAME} ${BIN_PATH}

uninstall:
	rm -f ${BIN_PATH}/${TOOL_NAME}

clean:
	rm -rf build
	rm -f output.toml

run:
	build/${TOOL_NAME} \
	--benchmarks benchmark-suite/benchmarks/mcore-ocaml \
	--runtimes benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--log info \
	--warmups 1 > results.toml

run-ppl:
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters 2 \
		--output toml \
		--warmups 1

run-test:
	build/${TOOL_NAME} \
	--benchmarks benchmark-suite/test/benchmarks \
	--runtimes benchmark-suite/runtimes \
	--runtimes benchmark-suite/test/runtimes \
	--iters 5 \
	--output toml \
	--log info \
	--timeout-sec 1 \
	--warmups 1

test:
	mi compile --test tool/tool/config-scanner.mc; ./config-scanner
	mi compile --test tool/tool/runner.mc; ./runner
	mi compile --test tool/tool/utils.mc; ./utils
	mi compile --test tool/tool/path.mc; ./path
	mi compile --test tool/tool/types.mc; ./types


#################################################
## PPL experiments. Temporarily specified here ##
#################################################
number_iterations=15
number_warmups=1
prefix=A

experiment_example=example
run-experiment-example:
	find . -name $(experiment_example).toml.skip -execdir cp '{}' $(experiment_example).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters 1 \
		--output toml \
		--log info \
		--warmups 0
	cp output.toml output-example.toml
	find . -name $(experiment_example).toml -delete


experiment_crbd=experiment-CRBD
run-experiment-CRBD:
	find . -name $(experiment_crbd).toml.skip -execdir cp '{}' $(experiment_crbd).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--output toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-$(experiment_crbd).toml
	find . -name $(experiment_crbd).toml -delete

experiment_optimized_crbd=experiment-OptimizedCRBD
run-experiment-OptimizedCRBD:
	find . -name $(experiment_optimized_crbd).toml.skip -execdir cp '{}' $(experiment_optimized_crbd).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--output toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-OptimizedCRBD.toml
	find . -name $(experiment_optimized_crbd).toml -delete


run-experiment-ClaDS:
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--output toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-ClaDS.toml
	rm benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml

experiment_SSM=experiment-SSM
run-experiment-SSM:
	find . -name $(experiment_SSM).toml.skip -execdir cp '{}' $(experiment_SSM).toml ';'
	build/${TOOL_NAME} \
		--benchmarks benchmark-suite/benchmarks/ppl \
		--runtimes benchmark-suite/runtimes \
		--iters $(number_iterations) \
		--output toml \
		--log info \
		--warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-SSM.toml
	find . -name $(experiment_SSM).toml -delete
