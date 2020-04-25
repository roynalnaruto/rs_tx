defmodule RsTxApiWeb.Schema.ConnectionTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  enum :sort_order do
    description("Sort order")

    value(:asc, description: "Ascending order")
    value(:desc, description: "Descending order")
  end
end
