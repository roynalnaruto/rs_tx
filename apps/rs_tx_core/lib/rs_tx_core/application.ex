defmodule RsTxCore.Application do
  @moduledoc false

  use Application

  alias RsTxCore, as: App

  def start(_type, _args) do
    children =
      [
        App.Repo
      ]
      |> Enum.reject(&is_nil/1)

    opts = [strategy: :one_for_one, name: RsTxCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
