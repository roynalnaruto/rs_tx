defmodule RsTxCore.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: RsTxCore.Repo

  alias RsTxCore.Factories.{
    AccountsFactory,
    AttachmentFactory,
    ProjectFactory,
    ProjectsFactory,
    UserFactory
  }

  use AttachmentFactory
  use UserFactory
  use ProjectFactory

  use AccountsFactory
  use ProjectsFactory
end
