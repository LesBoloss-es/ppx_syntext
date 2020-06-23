(* This file uses ppx_lwt as an example, showing it can be rewritten completely
   inside of Syntext. Declaring to Syntext that it should handle "lwt" as an
   extension, and giving it this file will make it a drop-in replacement of
   ppx_lwt 2.0.1. All definitions are really close to what one can find in
   ppx_lwt, except for the let that has to be handled a bit differently. *)

external reraise : exn -> 'a = "%reraise"

let seq e1 e2 =
  Lwt.backtrace_bind
    (fun exn -> try reraise exn with exn -> exn)
    e1 (fun () -> e2)

let let_ vb e =
  Lwt.backtrace_bind
    (fun exn -> try reraise exn with exn -> exn)
    (vb ()) e

let and_ e1 e2 =
  Lwt.backtrace_bind
    (fun exn -> try reraise exn with exn -> exn)
    (e1 ()) (fun v1 ->
        Lwt.backtrace_bind
          (fun exn -> try reraise exn with exn -> exn)
          (e2 ()) (fun v2 ->
              Lwt.return (v1, v2)))

let match_ e cases =
  Lwt.bind (e ()) cases

let assert_ e =
  try Lwt.return (assert e) with exn -> Lwt.fail exn

let assert_false () =
  try Lwt.return (assert false) with exn -> Lwt.fail exn

let while_ cond body =
  let rec __ppx_lwt_loop () =
    if cond () then Lwt.bind (body ()) __ppx_lwt_loop
    else Lwt.return_unit
  in __ppx_lwt_loop ()

let for_ start dir bound body =
  let comp, op = match dir with
    | Syntext.Upto -> (>), (+)
    | Downto -> (<), (-)
  in
  let __ppx_lwt_bound : int = bound () in
  let rec __ppx_lwt_loop p =
    if comp p __ppx_lwt_bound then Lwt.return_unit
    else Lwt.bind (body ()) (fun () -> __ppx_lwt_loop (op p 1))
  in __ppx_lwt_loop (start ())

let try_ expr cases =
  Lwt.backtrace_catch
    (fun exn -> try reraise exn with exn -> exn)
    (fun () -> expr ())
    cases

let if_ cond e1 e2 =
  let e2 =
    match e2 with
    | None -> fun () -> Lwt.return_unit
    | Some e2 -> e2
  in
  let cases = function
    | true -> e1 ()
    | false -> e2 ()
  in
  Lwt.bind (cond ()) cases
