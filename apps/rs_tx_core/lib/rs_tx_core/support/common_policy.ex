defmodule RsTxCore.Support.CommonPolicy do
  @moduledoc false

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  def user_confirmed?(%User{confirmed?: false}),
    do: {:error, :user_unconfirmed}

  def user_confirmed?(_),
    do: :ok
end
