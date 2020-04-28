defmodule RsTxCore.Projects.ProjectPolicy do
  @moduledoc false

  @behaviour Bodyguard.Policy

  alias RsTxCore.Support.CommonPolicy

  @impl true
  def authorize(:create_project, user, _attrs) do
    CommonPolicy.user_confirmed?(user)
  end

  @impl true
  def authorize(_, _, _),
    do: false
end
