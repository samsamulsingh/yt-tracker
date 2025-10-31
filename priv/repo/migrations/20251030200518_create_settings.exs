defmodule YtTracker.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :string, null: false
      add :value, :text
      add :encrypted_value, :binary
      add :description, :string
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :uuid)
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      
      timestamps()
    end

    create unique_index(:settings, [:key, :tenant_id])
    create index(:settings, [:tenant_id])
    create index(:settings, [:user_id])
  end
end
