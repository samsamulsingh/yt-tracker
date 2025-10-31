defmodule YtTracker.Repo.Migrations.CreateSyncLogs do
  use Ecto.Migration

  def change do
    create table(:sync_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :channel_id, references(:youtube_channels, type: :binary_id, on_delete: :delete_all), null: false
      add :sync_type, :string, null: false, comment: "api, rss, or scraping"
      add :status, :string, null: false, comment: "success, failed, or in_progress"
      add :videos_fetched, :integer, default: 0
      add :videos_new, :integer, default: 0
      add :videos_updated, :integer, default: 0
      add :error_message, :text
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:sync_logs, [:channel_id])
    create index(:sync_logs, [:sync_type])
    create index(:sync_logs, [:status])
    create index(:sync_logs, [:started_at])
  end
end
