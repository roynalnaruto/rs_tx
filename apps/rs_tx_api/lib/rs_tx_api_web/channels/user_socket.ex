defmodule RsTxApiWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: RsTxApiWeb.Schema

  alias Guardian.Phoenix.Socket, as: GuardianSocket

  alias RsTxApi.Guardian, as: ApiGuardian

  def connect(params, socket) do
    params
    |> case do
      %{"token" => token} -> token
      %{"Authorization" => "Bearer " <> token} -> token
      _ -> ""
    end
    |> (&GuardianSocket.authenticate(socket, ApiGuardian, &1)).()
    |> case do
      {:ok, authed_socket} ->
        user = GuardianSocket.current_resource(authed_socket)

        authed_socket
        |> Absinthe.Phoenix.Socket.put_options(context: %{current_user: user})
        |> (&{:ok, &1}).()

      {:error, _} ->
        {:ok, socket}
    end
  end

  def id(_socket), do: nil
end
