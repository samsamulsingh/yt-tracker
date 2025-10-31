defmodule YtTracker.Repo.Migrations.CreateYoutubeChannels do
  use Ecto.Migration

  def change do
    create table(:youtube_channels, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :youtube_id, :string, null: false
      add :title, :string
      add :description, :text
      add :custom_url, :string
      add :thumbnail_url, :string
      add :uploads_playlist_id, :string
      add :subscriber_count, :bigint
      add :video_count, :bigint
      add :view_count, :bigint
      add :published_at, :utc_datetime
      
      # RSS polling metadata
      add :rss_url, :string
      add :rss_etag, :string
      add :rss_last_modified, :string
      add :last_polled_at, :utc_datetime
      add :last_video_published_at, :utc_datetime
      
      # WebSub (PubSubHubbub) support
      add :websub_subscribed, :boolean, default: false
      add :websub_expires_at, :utc_datetime
      add :websub_secret, :string
      
      add :active, :boolean, default: true, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:youtube_channels, [:tenant_id, :youtube_id])
    create index(:youtube_channels, [:tenant_id])
    create index(:youtube_channels, [:youtube_id])
    create index(:youtube_channels, [:active])
    create index(:youtube_channels, [:last_polled_at])
  end
end
