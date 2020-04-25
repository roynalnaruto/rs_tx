defmodule RsTxCore.Repo.Migrations.AddPasswordResetFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:password_reset_id, :binary_id, null: true)
    end

    create unique_index(:users, [:password_reset_id], where: "password_reset_id is not null")
  end
end
