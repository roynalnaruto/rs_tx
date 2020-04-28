defmodule RsTxCore.Projects.ProjectMetadata do
  @moduledoc false

  use RsTxCore.Schema

  alias RsTxCore.{Attachment, Repo}

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.Project

  alias Ecto.Changeset

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

  @spec add_changeset(t(), map()) :: Changeset.t()
  def add_changeset(%Entity{} = entity, attrs) do
    fields = [:url, :overview, :description]

    image_fields = [:icon]

    entity
    |> Repo.preload(image_fields)
    |> Changeset.cast(attrs, fields)
    |> Changeset.validate_required(fields)
    |> Changeset.cast_assoc(:icon)
    |> Changeset.validate_length(:overview, max: 255)
    |> validate_url(:url)
  end

  defp validate_url(changeset, field, opts \\ []) do
    Changeset.validate_change(changeset, field, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: nil} ->
          "is missing a scheme (e.g. https)"

        %URI{host: nil} ->
          "is missing a host"

        _ -> nil
      end
      |> case do
        error when is_binary(error) ->
          [{field, Keyword.get(opts, :message, error)}]

        _ ->
          []
      end
    end)
  end
end
