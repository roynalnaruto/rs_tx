defmodule RsTxApiWeb.ErrorHandler do
  @moduledoc false

  use Phoenix.Controller, namespace: RsTxApiWeb

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler

  def auth_error(conn, error, _opts) do
    body =
      case error do
        {:invalid_token, :token_not_found} ->
          %{message: "Token expired"}

        {:invalid_token, _} ->
          %{message: "Invalid token"}

        _ ->
          %{message: "Authentication error"}
      end
      |> Jason.encode!()

    json(conn, body)
  end
end
