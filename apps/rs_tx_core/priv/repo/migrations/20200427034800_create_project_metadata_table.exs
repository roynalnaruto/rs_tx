defmodule RsTxCore.Repo.Migrations.CreateProjectMetadataTable do
  use Ecto.Migration

  def change do
    create table(:project_metadata, primary_key: false) do
      add(:id, :binary_id, primary_key: true, autogenerate: true)

      add(:url, :string)
      add(:overview, :string)
      add(:description, :text)
      add(:icon_id,
        references(:attachments, column: :id, type: :binary_id, null: true))

      add(:project_id, references(:projects, column: :id, type: :binary_id, null: false))

      timestamps(type: :utc_datetime)
    end
  end
end
