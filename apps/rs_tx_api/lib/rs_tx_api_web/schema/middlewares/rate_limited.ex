defmodule RsTxApiWeb.Schema.Middlewares.RateLimited do
  @moduledoc false

  @behaviour Absinthe.Middleware

  alias Hammer

  def call(%{state: :unresolved} = res, opts) do
    action =
      case Keyword.get(opts, :action) do
        action_name when is_binary(action_name) ->
          action_name

        action_function when is_function(action_function) ->
          action_function.(res.context)

        action ->
          action
      end

    scale_ms = Keyword.get(opts, :scale_ms, 60_000)
    limit = Keyword.get(opts, :limit, 300)

    case Hammer.check_rate(action, scale_ms, limit) do
      {:allow, count} ->
        new_context =
          res.context
          |> Map.put(:remaining_limit, count)
          |> Map.put(:limit, limit)

        %{res | context: new_context}

      {:deny, _limit} ->
        Absinthe.Resolution.put_result(res, {
          :error,
          "Rate Limited"
        })
    end
  end

  def call(res, _), do: res
end
