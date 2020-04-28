import Config

config :event_bus_logger,
  enabled: true,
  level: :debug,
  topics: ".*",
  light_logging: true

config :logger, :console, format: "[$level] $message\n"

config :hammer,
  backend: {
    Hammer.Backend.ETS,
    expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10
  }

config :mnesia,
  dir: './tmp'

config :phoenix,
  stacktrace_depth: 20,
  plug_init_mode: :runtime

config :rs_tx_core, RsTxCore.AssetsExplorer.ApiClient, response_timeout: :timer.seconds(30)

config :rs_tx_core, RsTxCore.Attachment,
  mime_types: ["image/gif", "image/jpeg", "image/png"],
  max_width: 2048,
  max_height: 2048,
  max_file_size: 10 * 1024 * 1024

config :rs_tx_core, RsTxCore.Repo,
  username: System.get_env("DB_USER", "rs_tx_user"),
  password: System.get_env("DB_PASSWORD", "rs_tx_pass"),
  database: System.get_env("DB_NAME", "rs_tx_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

config :rs_tx_api, RsTxApi.Guardian,
  issuer: "RsTx(Dev)",
  secret_key: "g0PytdoCT+zSaVriOCw48Kx7DxQXTYjUaDln5A8vidaZXRRQ6gSn4LbbuY3ss9fU",
  ttl: {3, :days},
  allowed_drift: 2000

if System.get_env("USE_SMTP", "") == "true" do
  config :rs_tx_api, RsTxApi.Mailer,
    adapter: Bamboo.SMTPAdapter,
    server: System.get_env("SMTP_HOST", "localhost"),
    port: System.get_env("SMTP_PORT", "25") |> String.to_integer(10)
else
  config :rs_tx_api, RsTxApi.Mailer, adapter: Bamboo.LocalAdapter
end

config :rs_tx_api, RsTxApi.MailerSubscriber,
  resend_delay: :timer.minutes(5),
  resend_limit: 10,
  retry_timeout: :timer.seconds(30)

config :rs_tx_api, RsTxApi.Emails, from: "noreply@rstx.io"

config :rs_tx_api, RsTxApi.Token,
  salt: "Ozg/Xenp0B+",
  reset_password_duration: div(:timer.hours(6), :timer.seconds(1))

config :rs_tx_api, RsTxApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "nVhUKXh51ho4iXEEeHT1DupyO/tgm/ANt1ipg6HXM4QM5fFOH7Fd1RQWTsHfWpJt",
  render_errors: [view: RsTxApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: RsTxApi.PubSub, adapter: Phoenix.PubSub.PG2]

config :rs_tx_api, RsTxApiWeb.Endpoint,
  http: [port: System.get_env("HTTP_PORT", "22001") |> String.to_integer(10)],
  https: [
    port: System.get_env("HTTPS_PORT", "22002") |> String.to_integer(10),
    keyfile: "priv/cert/dev.key",
    certfile: "priv/cert/dev.crt"
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :rs_tx_api, RsTxApi.Guardian,
  secret_key: "xnaJuMa//v+xvv3yNxSkHPK7DODIoAcEq5NeKBTVoBgDy/d2yz7eZs9ZuRCsyrnK"

config :rs_tx_api, RsTxApiWeb.AccountController,
  confirmation_uri: "https://localhost:5000/#/portal/login",
  reset_password_uri: "https://localhost:5000/#/portal/forgot-password/reset-form"
