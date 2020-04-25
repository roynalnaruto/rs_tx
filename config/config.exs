import Config

config :bodyguard,
  default_error: :unauthorized

config :cors_plug,
  headers: [
    "Authorization",
    "Content-Type",
    "Accept",
    "Origin",
    "User-Agent",
    "DNT",
    "Cache-Control",
    "X-Mx-ReqToken",
    "Keep-Alive",
    "X-Requested-With",
    "If-Modified-Since",
    "X-CSRF-Token",
    "X-Forwarded-For"
  ]

config :event_bus,
  id_generator: IdGenerator,
  topics: [
    :account_registered,
    :password_reset_requested,
    :password_changed
  ]

config :guardian, Guardian.DB,
  repo: RsTxCore.Repo,
  schema_name: "guardian_tokens",
  token_types: ["access"],
  sweep_interval: 60

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :rs_tx_core,
  ecto_repos: [RsTxCore.Repo]

config :rs_tx_api, RsTxApi.Mailer, adapter: Bamboo.LocalAdapter

config :rs_tx_api, RsTxApi.Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  verify_issuer: true

config :rs_tx_api, RsTxApiWeb.GuardianPipeline,
  module: RsTxApi.Guardian,
  error_handler: RsTxApiWeb.ErrorHandler

import_config "#{Mix.env()}.exs"
