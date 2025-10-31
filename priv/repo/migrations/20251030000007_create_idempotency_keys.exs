defmodule YtTracker.Repo.Migrations.CreateIdempotencyKeys do
  use Ecto.Migration

  def change do
    create table(:idempotency_keys, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :idempotency_key, :string, null: false
      add :request_path, :string, null: false
      add :request_method, :string, null: false
      add :request_params, :map
      add :response_status, :integer
      add :response_body, :text
      add :created_at, :utc_datetime, null: false
    end

    create unique_index(:idempotency_keys, [:tenant_id, :idempotency_key])
    create index(:idempotency_keys, [:created_at])
  end
end
