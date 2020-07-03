module type MonadWithError = sig
  type ('a, 'e) t

  val return : 'a -> ('a, 'e) t

  val bind : ('a, 'e) t -> ('a -> ('b, 'e) t) -> ('b, 'e) t
end

module type SigWithError = sig
  type ('a, 'e) t

  val seq : (unit -> (unit, 'e) t) -> (unit -> ('a, 'e) t) -> ('a, 'e) t

  val let_ : (unit -> ('a, 'e) t) -> ('a -> ('b, 'e) t) -> ('b, 'e) t

  val and_ : (unit -> ('a, 'e) t) -> (unit -> ('b, 'e) t) -> ('a * 'b, 'e) t

  val if_then : (unit -> (bool, 'e) t) -> (unit -> (unit, 'e) t) -> (unit, 'e) t
  val if_then_else : (unit -> (bool, 'e) t) -> (unit -> ('a, 'e) t) -> (unit -> ('a, 'e) t) -> ('a, 'e) t

  val match_ : (unit -> ('a, 'e) t) -> ('a -> ('b, 'e) t) -> ('b, 'e) t

  val while_ : (unit -> (bool, 'e) t) -> (unit -> (unit, 'e) t) -> (unit, 'e) t

  val for_ : (unit -> int) -> Common.direction -> (unit -> int) -> (unit -> (unit, 'e) t) -> (unit, 'e) t
end

module Make (M : MonadWithError) : SigWithError with type ('a, 'e) t = ('a, 'e) M.t = struct
  type ('a, 'e) t = ('a, 'e) M.t

  let let_ e1 e2 =
    M.bind (e1 ()) e2

  let seq = let_

  let and_ e1 e2 =
    M.bind (e1 ()) @@ fun v1 ->
    M.bind (e2 ()) @@ fun v2 ->
    M.return (v1, v2)

  let if_then_else e1 e2 e3 =
    M.bind (e1 ()) @@ fun v1 ->
    if v1 then e2 () else e3 ()

  let if_then e1 e2 =
    if_then_else e1 e2 M.return

  let match_ = let_

  let rec while_ e1 e2 =
    M.bind (e1 ()) @@ fun v1 ->
    if v1 then
      (
        M.bind (e2 ()) @@ fun () ->
        while_ e1 e2
      )
    else
      M.return ()

  let for_ e1 dir e2 e3 =
    let (+), (>) =
      match dir with
      | Common.Upto -> (+), (>)
      | Downto -> (-), (<)
    in
    let v1 = e1 () in
    let v2 = e2 () in
    let rec for_ i =
      if i > v2 then
        M.return ()
      else
        M.bind (e3 ()) @@ fun () ->
        for_ (i + 1)
    in
    for_ v1
end
