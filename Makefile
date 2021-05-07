.PHONY: run plot test

run:
	cd tool/main && \
	boot eval main.mc -- \
	--benchmarks ../../benchmark-suite/benchmarks \
	--runtimes ../../benchmark-suite/runtimes \
	--iters 5 \
	--output toml \
	--warmups 1 > ../../results.toml

run-ppl:
	boot eval tool/main/main.mc -- \
	  --benchmarks benchmark-suite/benchmarks/ppl \
	  --runtimes benchmark-suite/runtimes \
	  --iters 5 \
	  --output toml \
	  --warmups 1

plot:
	cd tool/main && \
	boot eval main.mc -- \
	--benchmarks ../../benchmark-suite/benchmarks \
	--plot ../../results.toml \
	&& convert *.png ../../report.pdf

test:
	cd tool/tool ; boot eval --test .
