defmodule RsTxCore.Projects.ProjectMetadata do
  @moduledoc false

  use RsTxCore.Schema

  alias RsTxCore.Attachment

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.Project

  alias __MODULE__, as: Entity

  @type t :: __MODULE__

  schema "project_metadata" do
    field(:url, :string)
    field(:overview, :string)
    field(:description, :string)

    belongs_to(:icon, Attachment,
      type: :binary_id,
      on_replace: :nilify
    )

    belongs_to(:project, Project, foreign_key: :project_id, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end
end
