defmodule RsTxCore.Projects.Project do
  @moduledoc false

  use RsTxCore.Schema

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.ProjectMetadata

  alias __MODULE__, as: Entity

  @type t :: __MODULE__

  schema "projects" do
    field(:public_key, :string)

    has_one(:metadata, ProjectMetadata, foreign_key: :project_id)

    belongs_to(:user, User, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end
end
