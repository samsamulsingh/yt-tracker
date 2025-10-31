defmodule YtTracker.Repo.Migrations.CreateWebhookEndpoints do
  use Ecto.Migration

  def change do
    create table(:webhook_endpoints, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :url, :string, null: false
      add :secret, :string, null: false
      add :active, :boolean, default: true, null: false
      
      # Event subscriptions (JSON array)
      add :events, {:array, :string}, default: ["*"], null: false
      
      add :description, :string
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:webhook_endpoints, [:tenant_id])
    create index(:webhook_endpoints, [:active])
  end
end
