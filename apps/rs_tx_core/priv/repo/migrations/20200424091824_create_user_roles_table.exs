defmodule RsTxCore.Repo.Migrations.CreateUserRolesTable do
  use Ecto.Migration

  def change do
    create table(:user_roles, primary_key: false) do
      add(:id, :binary_id, primary_key: true, autogenerate: true)
      add(:role_id, references(:roles, column: :id, type: :binary_id, null: false))
      add(:user_id, references(:users, column: :id, type: :binary_id, null: false))

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_roles, [:role_id, :user_id])
  end
end
