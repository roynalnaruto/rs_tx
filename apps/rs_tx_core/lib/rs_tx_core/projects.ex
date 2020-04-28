defmodule RsTxCore.Projects do
  @moduledoc false

  alias RsTxCore.Repo

  alias RsTxCore.Accounts, as: AccountContext

  alias RsTxCore.Projects, as: ProjectContext
  alias ProjectContext.{Project, ProjectMetadata, ProjectPolicy}

  alias Ecto.{Changeset, Multi, UUID}

  @type id :: UUID.t()

  @spec get_by_id(id) :: Project.t() | nil
  def get_by_id(id) do
    Repo.get_by(Project, id: id)
  end

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
        :create_project,
        fn repo, _ ->
          %Project{user_id: user_id}
          |> repo.insert()
        end
      )
      |> Multi.run(
        :create_metadata,
        fn repo, %{create_project: project} ->
          %ProjectMetadata{project_id: project.id}
          |> ProjectMetadata.add_changeset(metadata_attrs)
          |> repo.insert()
        end
      )
      |> Multi.run(
        :update_project,
        fn repo, %{create_project: project} ->
          project
          |> Project.create_changeset(attrs)
          |> repo.update()
        end
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{update_project: project}} ->
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

  @spec update_project(id, id, map()) ::
          {:ok, Project.t(), ProjectMetadata.t()}
          | {:error, :user_not_found}
          | {:error, :project_not_found}
          | {:error, :action_invalid, atom()}
          | {:error, Changeset.t()}
  def update_project(user_id, project_id, attrs) do
    with {:ok, user} <-
           if(user = AccountContext.get_by_id(user_id),
             do: {:ok, user},
             else: {:error, :user_not_found}
           ),
         {:ok, project} <-
           if(project = ProjectContext.get_by_id(project_id),
             do: {:ok, Repo.preload(project, :metadata)},
             else: {:error, :project_not_found}
           ),
         :ok <- check_policy(:update_project, user, project) do
      %{
        metadata: metadata_attrs
      } = attrs

      Multi.new()
      |> Multi.run(
        :update_metadata,
        fn repo, _ ->
          project.metadata
          |> ProjectMetadata.update_changeset(metadata_attrs)
          |> repo.update()
        end
      )
      |> Multi.run(
        :update_project,
        fn repo, _ ->
          project
          |> Project.update_changeset(attrs)
          |> repo.update()
        end
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{update_project: project, update_metadata: metadata}} ->
          {
            :ok,
            project,
            metadata
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
