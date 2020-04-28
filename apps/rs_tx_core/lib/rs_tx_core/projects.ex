defmodule RsTxCore.Projects do
  @moduledoc false

  alias RsTxCore.Repo

  alias RsTxCore.Accounts, as: AccountContext

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.{Project, ProjectMetadata, ProjectPolicy}

  alias Ecto.{Changeset, Multi, UUID}

  @type id :: UUID.t()

  @spec create_project(id, map()) ::
          {:ok, Project.t()}
          | {:error, :user_not_found}
          | {:error, :action_invalid, atom()}
          | {:error, Changeset.t()}
  def create_project(user_id, attrs) do
    with {:ok, user} <-
           if(user = AccountContext.get_by_id(user_id),
             do: {:ok, user},
             else: {:error, :user_not_found}
           ),
         :ok <- check_policy(:create_project, user, nil) do
      %{
        metadata: metadata_attrs
      } = attrs

      Multi.new()
      |> Multi.run(
        :project,
        fn repo, _ ->
          %Project{user_id: user_id}
          |> repo.insert()
        end
      )
      |> Multi.run(
        :metadata,
        fn repo, %{project: project} ->
          %ProjectMetadata{project_id: project.id}
          |> ProjectMetadata.add_changeset(metadata_attrs)
          |> repo.insert()
        end
      )
      |> Multi.run(
        :create_project,
        fn repo, %{project: project} ->
          project
          |> Project.create_changeset(attrs)
          |> repo.update()
        end
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{create_project: project}} ->
          {
            :ok,
            Repo.preload(project, :metadata)
          }

        {:error, _, %Changeset{} = changeset, _} ->
          {:error, changeset}
      end
    else
      error -> error
    end
  end

  defp check_policy(action, user, attrs) do
    case Bodyguard.permit(ProjectPolicy, action, user, attrs) do
      :ok -> :ok
      {:error, reason} -> {:error, :action_invalid, reason}
    end
  end
end
