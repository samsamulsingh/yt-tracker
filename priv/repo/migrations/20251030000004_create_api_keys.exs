defmodule YtTracker.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :key_hash, :string, null: false
      add :key_prefix, :string, null: false
      add :active, :boolean, default: true, null: false
      
      # Rate limiting per key
      add :rate_limit, :integer # requests per window
      add :rate_window_seconds, :integer
      
      # Permissions/scopes (JSON array)
      add :scopes, {:array, :string}, default: []
      
      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_keys, [:key_hash])
    create unique_index(:api_keys, [:key_prefix])
    create index(:api_keys, [:tenant_id])
    create index(:api_keys, [:active])
  end
end
