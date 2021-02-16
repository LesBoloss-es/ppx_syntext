*Syntext*: Generic Syntax Extension PPX for OCaml
=================================================

*Syntext* aims at allowing users to easily define their own PPX syntax extension
for OCaml. It comes with various helpers to write such extensions and a set of
pre-defined plugins. These cover natural extensions associated with types from
the standard library and one extra "dynamic" plugin.

Plugins
-------

### How To Use Standard Plugins

*Syntext* comes with predefined plugins for types from OCaml's standard library.
This includes `list`, `option` and `result`. They are all gathered in a common
plugin, `std`. With Dune, it is simply a matter of adding a preprocess directive
to your target:

```
(executable
 (name example)
 (preprocess (pps ppx_syntext.std)))
```

With an other build system, make sure `-package ppx_syntext.std` is passed to
OCaml. With ocamlbuild, this goes by adding something like the following to
`_tags`:

```
<src/*>: package(ppx_syntext.std)
```

### What Standard Plugins Do

Most types in the standard library admit a natural monad. The option type, for
instance, admits the following monad:

```ocaml
type 'a t = 'a option

let return x = Some x

let bind x f =
  match x with
  | None -> None
  | Some x -> f x
```

*(In fact, since OCaml 4.08.0, the `'a t` type and `bind` function are defined
in the `Option` module of the standard library. The `return` function is
actually called `some`.)*

*Syntext* then simply rewrites the control structures into their natural monadic
version. A let binding as follows:

```ocaml
let%option x = e1 in e2
```

will become:

```ocaml
Option.bind e1 (fun x -> e2)
```

Note here that `x` is *a priori* a free variable in `e2`. Otherwise, the second
code will trigger OCaml's warning 27 (unused variable) on `x` which will be
reported in the first code also on `x`. Since `Option.bind` only exists since
OCaml 4.08.0, *Syntext* in fact rewrites the aforementioned let binding into an
inlined version of `bind`:

```ocaml
match e1 with Some x -> e2 | None
```

*(In the rest of this explanation, for the sake of this explanation, we do not
inline the code of the monadic functions.)*

As a further example, a pattern matching with patterns `p1` to `pn` and guards
`g1` to `gn` returning expressions `e1` to `en`:

```ocaml
match%option e with
| p1 when g1 -> e1
| ...
| pn when gn -> en
```

becomes:

```ocaml
Option.bind e
  (function
   | p1 when g1 -> e1
   | ...
   | pn when gn -> en)
```

Some monads also have an error aspect. This is the case of the option monad, for
instance. More importantly, this is the case of the result monad which can also
actually carry the exceptions. These monads not only have `return` and `bind`
functions, but also `return_error` and `bind_error`. For instance:

```ocaml
type ('a, 'b) t = ('a, 'b) result

let return v = Ok v

let bind r f =
  match r with
  | Ok v -> f v
  | Error e -> Error e

let return_error e = Error e

let bind_error r f =
  match r with
  | Ok v -> Ok v
  | Error e -> f e
```

*(Since OCaml 4.08.0, the `('a, 'b) t` type and `bind` function are defined in
the `Result` module of the standard library. The `return` and `return_error`
functions are called `ok` and `error`. The `bind_error` function is not
provided.)*

These functions allow *Syntext* to rewrite error control structures (assert, try
and, to a lower extent, match) into their monadic versions. For instance, a try
with exception patterns `exn1` to `exnm` returning expressions `e1` to `em`:

```ocaml
try%result
  e
with
| exn1 -> e1
| ...
| exnm -> em
```

becomes:

```ocaml
Result.bind_error e
  (function
   | exn1 -> e1
   | ...
   | exnm -> em
   | any -> Error any)
```

Note that, contrary to pattern matchings, OCaml exception matchings in try
constructs are not necessarily complete. This is the reason behind this extra
`any` pattern.

As a last example, a pattern matching with patterns `p1` to `pn` and guards `g1`
to `gn` returning expressions `e1` to `en` and exceptional patterns `exn1` to
`exnm` returning expressions `e'1` to `e'm`:

```ocaml
match%result e with
| p1 when g1 -> e1
| ...
| pn when gn -> en
| exception exn1 -> e'1
| ...
| exception exnm -> e'm
```

is handled as:

```ocaml
try%result
  match%result e with
  | p1 when g1 -> e1
  | ...
  | pn when gn -> en
with
| exn1 -> e'1
| ...
| exnm -> e'm
| any -> Error any
```

This is not entirely true as, in the latter code, errors returned by an `ei`
would be caught by the `try` construct while, in the former code, they would
not. But heh, you get the idea.

### How To Use the "Dynamic" Plugin

**not implemented yet**

How To Write Your Own Plugin
----------------------------

**work in progress**

License
-------

TL;DR: [LGPL v3.0 or later](https://spdx.org/licenses/LGPL-3.0-or-later.html);
see [COPYING](COPYING.md) and [COPYING.LESSER](COPYING.LESSER.md).

Copyright © 2020–2021 Nicolas “Niols” Jeannerod

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the [GNU General Public License](COPYING.md)
and of the [GNU Lesser General Public License](COPYING.LESSER.md) along with
this program. If not, see <https://www.gnu.org/licenses/>.
