defmodule YtTracker.Repo.Migrations.CreateWebhookDeliveries do
  use Ecto.Migration

  def change do
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :endpoint_id, references(:webhook_endpoints, type: :uuid, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false # "pending", "sent", "failed", "retrying"
      
      # Retry logic
      add :attempt_count, :integer, default: 0, null: false
      add :max_attempts, :integer, default: 5, null: false
      add :next_attempt_at, :utc_datetime
      
      # Response tracking
      add :response_status, :integer
      add :response_body, :text
      add :error, :text
      
      add :sent_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:webhook_deliveries, [:tenant_id])
    create index(:webhook_deliveries, [:endpoint_id])
    create index(:webhook_deliveries, [:status])
    create index(:webhook_deliveries, [:next_attempt_at])
    create index(:webhook_deliveries, [:event_type])
  end
end
