import Config

config :bcrypt_elixir, log_rounds: 4

config :event_bus_logger,
  enabled: false

config :hammer,
  backend: {
    Hammer.Backend.ETS,
    expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10
  }

config :logger, level: :warn

config :mnesia,
  dir: './tmp/test'

config :propcheck,
  counter_examples: "./tmp/test"

config :rs_tx_core, RsTxCore.Attachment,
  mime_types: ["image/gif", "image/jpeg", "image/png"],
  max_width: 6000,
  max_height: 6000,
  max_file_size: 10 * 1024 * 1024

config :rs_tx_core, RsTxCore.Document, max_file_size: 10 * 1024 * 1024

config :rs_tx_core, RsTxCore.Repo,
  username: "rs_tx_user",
  password: "rs_tx_pass",
  database: "rs_tx_test",
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  pool: Ecto.Adapters.SQL.Sandbox

config :rs_tx_api, RsTxApi.Guardian,
  issuer: "RsTx(Test)",
  secret_key: "j5fsOWZza+8//q4tb8jCUldh7Rjk0pMDIZ/TwV00JkQVKmrY8vy9bRQBrvwJwvAB"

config :rs_tx_api, RsTxApi.Mailer, adapter: Bamboo.TestAdapter

config :rs_tx_api, RsTxApi.MailerSubscriber,
  resend_delay: :timer.seconds(5),
  resend_limit: 5,
  retry_timeout: :timer.seconds(3)

config :rs_tx_api, RsTxApi.Emails, from: "noreply@rstx.io"

config :rs_tx_api, RsTxApi.Token,
  salt: "KWliQDD3D9u85wU9QPja+",
  reset_password_duration: div(:timer.hours(6), :timer.seconds(1))

config :rs_tx_api, RsTxApi.IpAccess, whitelisted_ips: ["127.0.0.1"]

config :rs_tx_api, RsTxApiWeb.Endpoint,
  http: [port: 22005],
  secret_key_base: "nVhUKXh51ho4iXEEeHT1DupyO/tgm/ANt1ipg6HXM4QM5fFOH7Fd1RQWTsHfWpJt",
  pubsub: [name: RsTxApi.PubSub, adapter: Phoenix.PubSub.PG2]

config :rs_tx_api, RsTxApiWeb.AccountController,
  confirmation_uri: "https://127.0.0.1:5000/#/portal/register/confirmation",
  reset_password_uri: "https://127.0.0.1:5000/#/portal/forgot-password/reset-form"
