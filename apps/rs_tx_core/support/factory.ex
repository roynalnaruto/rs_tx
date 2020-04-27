defmodule RsTxCore.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: RsTxCore.Repo

  alias RsTxCore.Factories.{
    AccountsFactory,
    AttachmentFactory,
    ProjectFactory,
    UserFactory
  }

  use AttachmentFactory
  use UserFactory
  use ProjectFactory

  use AccountsFactory
end
