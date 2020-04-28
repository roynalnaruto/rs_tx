defmodule RsTxCore.Projects.ProjectPolicy do
  @moduledoc false

  @behaviour Bodyguard.Policy

  alias RsTxCore.Support.CommonPolicy

  @impl true
  def authorize(:create_project, user, _attrs) do
    CommonPolicy.user_confirmed?(user)
  end

  @impl true
  def authorize(:update_project, user, project) do
    with :ok <- CommonPolicy.user_confirmed?(user) do
      cond do
        user.id != project.user_id -> {:error, :not_user_project}

        true -> :ok
      end
    else
      error -> error
    end
  end

  @impl true
  def authorize(_, _, _),
    do: false
end
