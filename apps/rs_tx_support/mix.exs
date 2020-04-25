defmodule RsTxSupport.MixProject do
  use Mix.Project

  def project do
    [
      app: :rs_tx_support,
      version: "0.4.2",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(:dev), do: ["lib", "support"]
  defp elixirc_paths(:prod), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:honeydew, "~> 1.4.4", optional: true},
      {:propcheck, "~> 1.2.0", only: :test},
      {:ex_spec, "~> 2.0", only: :test}
    ]
  end
end
