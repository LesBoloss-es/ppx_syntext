(* module type Monad = sig
 *   type 'a t
 * 
 *   val return : 'a -> 'a t
 * 
 *   val bind : 'a t -> ('a -> 'b t) -> 'b t
 * end
 * 
 * module type Sig = sig
 *   type 'a t
 * 
 *   val seq : (unit -> unit t) -> (unit -> 'a t) -> 'a t
 * 
 *   val let_ : (unit -> 'a t) -> ('a -> 'b t) -> 'b t
 * 
 *   val and_ : (unit -> 'a t) -> (unit -> 'b t) -> ('a * 'b) t
 * 
 *   val if_then : (unit -> bool t) -> (unit -> unit t) -> unit t
 *   val if_then_else : (unit -> bool t) -> (unit -> 'a t) -> (unit -> 'a t) -> 'a t
 * 
 *   val match_ : (unit -> 'a t) -> ('a -> 'b t) -> 'b t
 * 
 *   val while_ : (unit -> bool t) -> (unit -> unit t) -> unit t
 * 
 *   val for_ : (unit -> int) -> Common.direction -> (unit -> int) -> (unit -> unit t) -> unit t
 * end
 * 
 * module Make (M : Monad) : Sig with type 'a t = 'a M.t = struct
 *   include FromMonadWithError.Make(struct
 *       include M
 * 
 *       type ('a, 'e) t = 'a M.t
 *     end)
 * 
 *   type 'a t = 'a M.t
 * end *)
