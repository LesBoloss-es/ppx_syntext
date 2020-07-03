
let config = Syntext.Config.(
    default
    |> add_extension "lwt"
    |> set_module_for "lwt" "SyntextLwt"
  )

let () = Syntext.Mapper.register ~name:"ppx_syntext" ~config ()
