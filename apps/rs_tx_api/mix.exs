defmodule RsTxApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :rs_tx_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :logger_file_backend, :toml],
      mod: {RsTxApi.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.1.0"},
      {:plug_cowboy, "~> 2.1.0"},
      {:plug_checkup, "~> 0.3.0"},
      {:cors_plug, "~> 2.0.0"},
      {:remote_ip, "~> 0.1.0"},
      {:hammer, "~> 6.0.0"},
      {:ex_url, "~> 1.1"},
      {:absinthe, "~> 1.4.0"},
      {:absinthe_phoenix, "~> 1.4.0"},
      {:absinthe_relay, "~> 1.4.6"},
      {:guardian, "~> 1.2.0"},
      {:guardian_db, "~> 2.0.0"},
      {:honeydew, "~> 1.4.4"},
      {:cachex, "~> 3.2.0"},
      {:timex, "~> 3.5"},
      {:bamboo, "~> 1.3.0"},
      {:bamboo_postmark, "~> 0.6.0"},
      {:bamboo_smtp, "~> 2.0.0", only: :dev},
      {:event_bus, "~> 1.6.1"},
      {:logger_file_backend, "~> 0.0.10"},
      {:rs_tx_core, in_umbrella: true},
      {:rs_tx_support, in_umbrella: true}
    ]
  end
end
