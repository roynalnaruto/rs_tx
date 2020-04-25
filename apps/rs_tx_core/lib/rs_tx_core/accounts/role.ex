defmodule RsTxCore.Accounts.Role do
  @moduledoc false

  use RsTxCore.Schema

  alias RsTxCore.Accounts.UserRole

  @type t :: __MODULE__

  schema "roles" do
    field(:name, RoleEnum)
    has_many(:role_users, UserRole)
    has_many(:users, through: [:role_users, :user])

    timestamps(type: :utc_datetime)
  end
end
