.PHONY: run test

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
	mi test tool/path.mc
	mi test tool/utils.mc
