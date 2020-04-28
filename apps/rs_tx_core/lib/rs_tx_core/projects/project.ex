defmodule RsTxCore.Projects.Project do
  @moduledoc false

  use RsTxCore.Schema

  alias RsTxCore.Accounts, as: AccountContext
  alias AccountContext.User

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.ProjectMetadata

  alias Ecto.Changeset

  alias __MODULE__, as: Entity

  @type t :: __MODULE__

  @public_key_regex ~r/^(0x)?[0-9a-fA-F]{66}$/i

  schema "projects" do
    field(:public_key, :string)

    has_one(:metadata, ProjectMetadata, foreign_key: :project_id)

    belongs_to(:user, User, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  @spec create_changeset(t(), map()) :: Changeset.t()
  def create_changeset(%Entity{} = entity, attrs) do
    fields = [:public_key]

    entity
    |> Changeset.cast(attrs, fields)
    |> Changeset.validate_required(fields)
    |> Changeset.validate_format(:public_key, @public_key_regex)
  end

  @spec update_changeset(t(), map()) :: Changeset.t()
  def update_changeset(%Entity{} = entity, attrs) do
    fields = [:public_key]

    entity
    |> Changeset.cast(attrs, fields)
    |> Changeset.validate_format(:public_key, @public_key_regex)
  end
end
