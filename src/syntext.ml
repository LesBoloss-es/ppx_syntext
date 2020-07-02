include Common

module Config = Config
module Mapper = Mapper

module FromMonad (M : FromMonad.Monad)
  : FromMonad.Sig with type 'a t = 'a M.t =
struct
  include FromMonad.Make (M)
end

module FromMonadWithError (M : FromMonadWithError.MonadWithError)
  : FromMonadWithError.SigWithError with type ('a, 'e) t = ('a, 'e) M.t =
struct
  include FromMonadWithError.Make (M)
end

module Opt = struct
  include FromMonad(struct
      type 'a t = 'a option

      let return x = Some x

      let bind x f =
        match x with
        | None -> None
        | Some x -> f x
    end)

  let assert_ e =
    if e () then Some () else None
end

module Result = struct
  include FromMonadWithError(struct
      type ('a, 'e) t = ('a, 'e) result

      let return x = Ok x

      let bind x f =
        match x with
        | Ok x -> f x
        | Error y -> Error y
    end)

  let assert_ e =
    try Ok (assert e) with exn -> Error exn

  let try_ e cases =
    match e () with
    | Ok x -> Ok x
    | Error y -> cases y
end
