defmodule RsTxCore.PropertyType do
  @moduledoc false

  use PropCheck

  def string(min, max) do
    base_string =
      let count <- integer(min, max) do
        let raw_string <- binary(count) do
          raw_string
          |> String.trim(<<0>>)
          |> String.trim()
        end
      end

    such_that(
      new_string <- base_string,
      when: String.length(new_string) >= min
    )
  end
end
