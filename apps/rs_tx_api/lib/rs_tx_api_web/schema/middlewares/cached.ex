defmodule RsTxApiWeb.Schema.Middlewares.Cached do
  @moduledoc false

  @behaviour Absinthe.Middleware
  @behaviour Absinthe.Plugin

  alias Cachex

  alias RsTxApi.Cache

  def resolver(fun, opts \\ []) do
    fn object, args, res ->
      {:middleware, __MODULE__, {fun, opts}}
    end
  end

  def call(%{state: :unresolved} = res, {resolver, opts}) do
    key =
      case Keyword.get(opts, :key) do
        key when is_binary(key) -> key
        key_fun when is_function(key_fun) -> key_fun.(res.arguments, res.context)
        _ -> raise "Cache key error"
      end

    case Cachex.get(Cache.cache(), key) do
      {:ok, nil} ->
        case Absinthe.Resolution.call(res, resolver) do
          %{state: :resolved, value: value} = updated_res ->
            Cachex.put!(Cache.cache(), key, value)

            updated_res

          failed_res ->
            failed_res
        end

      {:ok, value} ->
        Absinthe.Resolution.put_result(res, {:ok, value})
    end
  end

  def call(res, _),
    do: res
end
