defmodule RsTxApi.Token do
  @moduledoc false

  alias Phoenix.Token

  alias RsTxApiWeb.Endpoint

  def sign(data, opts \\ []) do
    Token.sign(Endpoint, salt(), data, opts)
  end

  def verify(token, opts \\ []) do
    Token.verify(Endpoint, salt(), token, opts)
  end

  defp salt() do
    config()[:salt]
  end

  defp config() do
    Application.fetch_env!(:rs_tx_api, __MODULE__)
  end
end
