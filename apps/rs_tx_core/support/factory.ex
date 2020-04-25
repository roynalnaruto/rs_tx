defmodule RsTxCore.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: RsTxCore.Repo

  alias RsTxCore.Factories.{
    AccountsFactory,
    UserFactory
  }

  use UserFactory

  use AccountsFactory
end
