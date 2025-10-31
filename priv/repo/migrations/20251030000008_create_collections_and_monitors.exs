defmodule YtTracker.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :auto_add_enabled, :boolean, default: false
      add :filters, :map, default: %{}
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:collections, [:tenant_id])

    # Junction table for collections and videos
    create table(:collection_videos, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :collection_id, references(:collections, type: :uuid, on_delete: :delete_all), null: false
      add :video_id, references(:youtube_videos, type: :uuid, on_delete: :delete_all), null: false
      add :added_at, :utc_datetime, null: false
      add :added_by, :string # 'manual' or 'auto'
    end

    create unique_index(:collection_videos, [:collection_id, :video_id])
    create index(:collection_videos, [:collection_id])
    create index(:collection_videos, [:video_id])

    # Monitoring configuration for channels
    create table(:channel_monitors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :channel_id, references(:youtube_channels, type: :uuid, on_delete: :delete_all), null: false
      add :enabled, :boolean, default: true
      add :check_frequency_minutes, :integer, default: 15
      add :last_check_at, :utc_datetime
      add :next_check_at, :utc_datetime
      add :auto_add_to_collections, {:array, :uuid}, default: []
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:channel_monitors, [:channel_id])
    create index(:channel_monitors, [:enabled])
    create index(:channel_monitors, [:next_check_at])

    # Video processing cache
    create table(:video_cache, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :video_id, references(:youtube_videos, type: :uuid, on_delete: :delete_all), null: false
      add :processed, :boolean, default: false
      add :processed_at, :utc_datetime
      add :processing_rules, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:video_cache, [:video_id])
    create index(:video_cache, [:processed])
  end
end
