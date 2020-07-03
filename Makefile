.PHONY: build install uninstall test clean

build:
	dune build @install

install:
	dune install

uninstall:
	dune uninstall

test:
	dune test

clean:
	dune clean
