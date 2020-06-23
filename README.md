Syntext: Generic Syntax Extension PPX for OCaml
===============================================

*Syntext* is a PPX rewriter that is meant to allow users to define easily their
own PPX extension in pure OCaml.

**This is still very much work in progress.**

Introduction
------------

*Syntext* is not doing much, actually. It simply replaces common structures that
have been marked with an extension flag by functions. For instance:

```ocaml
e1 ;%foo e2

let%foo x = e1 in e2

while%foo e1 do e2 done
```

would be rewritten in:

```ocaml
syntext_foo_seq (fun () -> e1) (fun () -> e2)

syntext_foo_let (fun () -> e1) (fun x -> e2)

syntext_foo_while (fun () -> e1) (fun () -> e2)
```

One can then easily provide a syntax extension by simply defining the according
functions. The fact that all expressions are passed as thunks allows a lot of
expressivity. For instance:

```ocaml
let syntext_foo_seq e1 e2 =
  e2 (); e1 ()
  
let syntext_foo_let e1 e2 =
  ignore (e1 ());
  e2 42

let syntext_foo_while e1 e2 =
  while e2 () do
    e1 ()
  done
```

Most of the time, however, one wants reasonable structures. *Syntext* thus
provides a functor that allows to derive reasonable definitions of these
functions out of a monad. For options, for instance:

```ocaml
module SyntextOptionFunctions = struct
  include Syntext.FromMonad(struct
    type 'a t = 'a option
    
    let return x = Some x
    
    let bind x f =
      match x with
      | Some x -> f x
      | None -> None
  end)
```

How to
------

*Syntext* will not guess which extensions to work on. You need to specify that
*via* its command line arguments. You can add as many extensions as you want
with the `--extension` (`-e` for short) flag. For an extension `foo`, *Syntext*
will replace the structures `*%foo` into `syntext_foo_*` functions. If you
prefer to have your function in a module, named directly like the structures,
you can specify in which modules one can find the functions with the `--module`
(`-m` for short) argument.

In Dune, to preprocess your file with *Syntext* and the two extensions `foo` and
`bar`, use:

```
(preprocess (pps ppx_syntext -- -e foo -e bar))
```

If the functions for `foo` are in a module `MyLib.SyntextFooFunctions`, use:

```
(preprocess (pps ppx_syntext -- -e foo -m MyLib.SyntextFooFunctions -e bar))
```

Urgent to-do list
-----------------

- Location of errors.
- A way to declare extensions on a per-file basis.
- Let *Syntext* run on all extensions, with a very low priority with respect to
  other rewriters, by default.
- An easy way to define a standalone PPX using ppx_syntext as a lib.
