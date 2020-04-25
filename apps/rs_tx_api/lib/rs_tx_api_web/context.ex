defmodule RsTxApiWeb.Context do
  @moduledoc false

  @behaviour Plug

  alias RsTxApi.Guardian, as: ApiGuardian

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    %{
      remote_ip:
        conn.remote_ip
        |> Tuple.to_list()
        |> Enum.join("."),
      current_user: ApiGuardian.Plug.current_resource(conn)
    }
  end
end
