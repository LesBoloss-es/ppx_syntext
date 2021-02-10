Tests
=====

The `nop` Test
--------------

The principle of this test is to write the same PPX rewriter with different
techniques and check that the same file, rewritten with the different rewriters,
gives codes that have the same semantics. For this example, we write various
files which use `%nop` structures. We then rewrite them with four "nop"
rewriters that do not alter the semantics of the program. We check that all four
rewritten codes run in the same way.

The `div` Test
--------------

This test provides several implementations of the division of `(int, exn)
result` values where division by `0` yields an `Assertion_failure`. These
implementations use different control structures to achieve the same result. A
reference implementation is written in pure OCaml. The output of all the
implementations are then compared.
