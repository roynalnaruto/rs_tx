defmodule RsTxApi.Cache do
  @moduledoc false

  use Supervisor

  alias Cachex

  @cache :api_cache

  def start_link(_opts) do
    Cachex.start_link(@cache, [])
  end

  def cache do
    @cache
  end
end
