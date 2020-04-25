defmodule RsTxCore.Accounts.UserRole do
  @moduledoc false

  use RsTxCore.Schema

  alias RsTxCore.Accounts.{
    User,
    Role
  }

  @type t :: __MODULE__

  schema "user_roles" do
    belongs_to(:role, Role, type: :binary_id)
    belongs_to(:user, User, type: :binary_id)

    timestamps(type: :utc_datetime)
  end
end
