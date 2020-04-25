defmodule RsTxApiWeb.Schema do
  @moduledoc nil

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias RsTxApiWeb.Schema

  import_types(Absinthe.Type.Custom)
  import_types(Schema.CustomScalarTypes)
  import_types(Schema.MutationTypes)
  import_types(Schema.ConnectionTypes)

  import_types(Schema.AccountTypes)

  query do
    import_fields(:account_queries)
  end

  mutation do
    import_fields(:account_mutations)
  end
end
