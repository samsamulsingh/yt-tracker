defmodule YtTracker.Repo.Migrations.AddLastApiSyncToChannels do
  use Ecto.Migration

  def change do
    alter table(:youtube_channels) do
      add :last_api_sync_at, :utc_datetime, comment: "Last time videos were synced via YouTube API"
    end

    create index(:youtube_channels, [:last_api_sync_at])
  end
end
