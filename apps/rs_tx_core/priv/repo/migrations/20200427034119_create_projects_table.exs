defmodule RsTxCore.Repo.Migrations.CreateProjectsTable do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add(:id, :binary_id, primary_key: true, autogenerate: true)

      add(:public_key, :string, size: 100, null: true)

      add(:user_id, references(:users, column: :id, type: :binary_id, null: false))

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:projects, [:public_key], where: "public_key is not null")
  end
end
