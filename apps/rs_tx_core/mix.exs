defmodule RsTxCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :rs_tx_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(:dev), do: ["lib", "support"]
  defp elixirc_paths(:prod), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :logger_file_backend, :postgrex, :toml],
      included_applications: [:mnesia],
      mod: {RsTxCore.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:ecto_enum, "~> 1.3"},
      {:event_bus, "~> 1.6.1"},
      {:event_bus_logger, "~> 0.1.6"},
      {:bcrypt_elixir, "~> 2.0"},
      {:bodyguard, "~> 2.4"},
      {:timex, "~> 3.5"},
      {:temp, "~> 0.4"},
      {:toml, "~> 0.5.2"},
      {:uuid, "~> 1.1.8", app: false, runtime: false, override: true},
      {:elixir_uuid, "~> 1.2.0", override: true},
      {:httpoison, "1.6.1", override: true},
      {:logger_file_backend, "~> 0.0.10"},
      {:mogrify, "~> 0.5.6"},
      {:mogrify_draw, "~> 0.1.0", only: [:dev, :test]},
      {:ex_machina, "~> 2.3", only: [:dev, :test]},
      {:faker, "~> 0.12.0", only: [:dev, :test]},
      {:propcheck, "~> 1.2.0", only: :test},
      {:ex_spec, "~> 2.0", only: :test},
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp aliases do
    [
      "db.migrate": "ecto.migrate",
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
