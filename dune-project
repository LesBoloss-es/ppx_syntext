(lang dune 2.5)

(allow_approximate_merlin)

(generate_opam_files true)

(version 0.1)

(license LGPL-3.0-or-later)
(authors "Niols <niols@niols.fr>")
(maintainers "Niols <niols@niols.fr>")
(source (github LesBoloss-es/ppx_syntext))

(package
 (name ppx_syntext)
 (synopsis "Generic syntax extension pre-processor")
 (description "Syntext provide a PPX rewriter that does all the generic stuff a syntax
extension pre-processor must do. Instead of replacing directly by the expression
that would be expected in this extension, it replaces them by functions. The
extension can then be written using only pure OCaml functions. For an extension
'foo' whose function are in module 'SyntextFoo', Syntext would replace

    if%foo e1 then e2 else e3

by

    SyntextFoo.if_then_else (fun () -> e1) (fun () -> e2) (fun () -> e3)

The behaviour of the if structure can then be defined purely in OCaml. For most
syntax extensions, the structures can be derived from an underlying monad.
Syntext thus provides a functor to produce these functions from only the bind
and return functions."))
