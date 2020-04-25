defmodule RsTxCore.Repo.Migrations.CreateRolesTable do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add(:id, :binary_id, primary_key: true, autogenerate: true)
      add(:name, :string, null: false)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])
  end
end
