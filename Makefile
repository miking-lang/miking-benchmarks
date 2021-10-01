.PHONY: run plot test

run:
	boot eval tool/main/main.mc -- \
	--benchmarks benchmark-suite/benchmarks/mcore-ocaml \
	--runtimes benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--log info \
	--warmups 1 > results.toml

run-ppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 2 \
	  --output toml \
	  --warmups 1

run-test:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/test/benchmarks \
	  --runtimes benchmark-suite/runtimes \
	  --runtimes benchmark-suite/test/runtimes \
	  --iters 5 \
	  --output toml \
	  --log info \
	  --timeout-s 1 \
	  --warmups 1


plot:
	boot eval tool/main/main.mc -- \
	--benchmarks benchmark-suite/benchmarks \
	--plot results.toml \
	&& convert *.png report.pdf

test:
	boot eval --test tool/tool


#################################################
## PPL experiments. Temporarily specified here ##
#################################################
number_iterations=15
number_warmups=1
prefix=A

experiment_example=example
run-experiment-example:
	find . -name $(experiment_example).toml.skip -execdir cp '{}' $(experiment_example).toml ';'
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 1 \
	  --output toml \
	  --warmups 0
	cp output.toml output-example.toml
	find . -name $(experiment_example).toml -delete


experiment_crbd=experiment-CRBD
run-experiment-CRBD:
	find . -name $(experiment_crbd).toml.skip -execdir cp '{}' $(experiment_crbd).toml ';'
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters $(number_iterations) \
	  --output toml \
	  --warmups $(number_warmups)
	cp output.toml output-$(prefix)-$(number_iterations)-$(experiment_crbd).toml
	find . -name $(experiment_crbd).toml -delete

experiment_optimized_crbd=experiment-OptimizedCRBD
run-experiment-OptimizedCRBD:
	find . -name $(experiment_optimized_crbd).toml.skip -execdir cp '{}' $(experiment_optimized_crbd).toml ';'
	boot eval tool/main/main.mc  -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters $(number_iterations) \
	  --output toml \
	  --warmups $(number_warmups)	
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-OptimizedCRBD.toml
	find . -name $(experiment_optimized_crbd).toml -delete


run-experiment-ClaDS:
	cp benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml.skip benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml
	boot eval tool/main/main.mc  -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters $(number_iterations) \
	  --output toml \
	  --warmups $(number_warmups)	
	cp output.toml output-$(prefix)-$(number_iterations)-experiment-ClaDS.toml
	rm benchmark-suite/benchmarks/ppl/rootppl/experiment-ClaDS.toml 
clean:
	rm output.toml
