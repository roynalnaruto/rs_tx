defmodule RsTxApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :rs_tx_api
  use Absinthe.Phoenix.Endpoint

  socket "/socket", RsTxApiWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :rs_tx_api,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 60_000_000

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_rs_tx_api_key",
    signing_salt: "TNQjOBxTAWqlMoMH2NwYzjdSTv4xHlKM3QwG3FgDVSkPYbJbbJCVcn7LVuWD3jaX"

  plug CORSPlug, origins: "*"
  plug RemoteIp
  plug RsTxApiWeb.Router
end
