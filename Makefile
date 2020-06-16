.PHONY: build test clean

build:
	dune build @install

test:
	dune test

clean:
	dune clean
