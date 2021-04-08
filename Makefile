.PHONY: run plot test

run:
	cd tool/main && \
	mi main.mc -- \
	--benchmarks ../../benchmark-suite/benchmarks \
	--runtimes ../../benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--warmups 1 > ../../results.toml

plot:
	cd tool/main && \
	mi main.mc -- \
	--benchmarks ../../benchmark-suite/benchmarks \
	--plot ../../results.toml \
	&& convert *.png ../../report.pdf

test:
	cd tool/tool ; mi test .
