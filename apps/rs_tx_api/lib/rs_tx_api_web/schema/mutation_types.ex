defmodule RsTxApiWeb.Schema.MutationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :field_error do
    description("An user-readable error")

    field(:field, :string,
      description: """
      Which input final value this error came from. If this is `null`, it is an mutation/operation error.
      """
    )

    field(:message, non_null(:string), description: "A description of the error")
  end
end
