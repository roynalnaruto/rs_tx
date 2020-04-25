defmodule RsTxCore.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :binary_id, primary_key: true, autogenerate: true)
      add(:email, :string, size: 254, null: false)
      add(:password_hash, :string, size: 254, null: false)
      add(:is_confirmed, :boolean, default: false, null: false)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
