defmodule RsTxCore.Repo.Migrations.CreateAttachmentsTable do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add(:id, :binary_id, primary_key: true, autogenerate: true)
      add(:original, :text, null: false)
      add(:thumbnail, :text, null: false)

      timestamps(type: :utc_datetime_usec)
    end
  end
end
