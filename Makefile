run:
	cd tool && \
	mi main.mc -- \
	--benchmarks ../benchmark-suite/benchmarks \
	--runtimes ../benchmark-suite/runtimes \
	--iters 5 \
	--dry-runs 1
