import Config

# Every `nil` value should be replaced by the config.toml in production
# You should have `config/prod.secret.toml` before deploying or compiling

config :event_bus_logger,
  enabled: true,
  level: :debug,
  topics: ".*",
  light_logging: true

config :hammer,
  backend: {
    Hammer.Backend.ETS,
    expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10
  }

config :logger, level: :debug

config :logger,
  compile_time_purge_level: :debug,
  backends: [
    :console,
    {LoggerFileBackend, :infolog},
    {LoggerFileBackend, :errorlog},
    {LoggerFileBackend, :debuglog}
  ]

config :logger, :console,
  format: "[$level] $message\n",
  metadata: :all,
  level: :info

config :logger, :infolog,
  path: "./info.log",
  level: :info

config :logger, :errorlog,
  path: "./error.log",
  level: :error

config :logger, :errorlog,
  path: "./debug.log",
  level: :debug

config :rs_tx_core, RsTxCore.Attachment,
  mime_types: nil,
  max_width: nil,
  max_height: nil,
  max_file_size: nil

config :rs_tx_core, RsTxCore.Repo,
  username: nil,
  password: nil,
  database: nil,
  hostname: nil

config :rs_tx_api, RsTxApi.Guardian,
  issuer: nil,
  secret_key: nil,
  ttl: {1, :days},
  allowed_drift: 2000

config :rs_tx_api, RsTxApi.Mailer,
  adapter: Bamboo.PostmarkAdapter,
  api_key: nil

config :rs_tx_api, RsTxApi.MailerSubscriber,
  resend_delay: :timer.minutes(30),
  resend_limit: 100,
  retry_timeout: :timer.minutes(30)

config :rs_tx_api, RsTxApi.Emails, from: nil

config :rs_tx_api, RsTxApi.Token,
  salt: nil,
  reset_password_duration: nil

config :rs_tx_api, RsTxApiWeb.AccountController,
  confirmation_uri: nil,
  reset_password_uri: nil,
  change_eth_address_confirmation_uri: nil,
  buy_dgx_uri: nil,
  draft_tier_2_kyc_uri: nil

config :rs_tx_api, RsTxApiWeb.Endpoint,
  url: [host: nil, port: nil],
  http: [:inet, port: nil],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: nil,
  render_errors: [view: RsTxApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: RsTxApiWeb.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  code_reloader: false,
  check_origin: false,
  watchers: []

if File.exists?("prod.secret.exs") do
  import_config "prod.secret.exs"
end
