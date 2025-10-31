defmodule YtTracker.Repo.Migrations.CreateYoutubeVideos do
  use Ecto.Migration

  def change do
    create table(:youtube_videos, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references(:tenants, type: :uuid, on_delete: :delete_all), null: false
      add :channel_id, references(:youtube_channels, type: :uuid, on_delete: :delete_all), null: false
      add :youtube_id, :string, null: false
      add :title, :string
      add :description, :text
      add :published_at, :utc_datetime
      add :thumbnail_url, :string
      
      # Video metadata
      add :duration, :string
      add :duration_seconds, :integer
      add :definition, :string # "hd" or "sd"
      add :dimension, :string # "2d" or "3d"
      add :caption, :string # "true" or "false"
      add :licensed_content, :boolean
      add :projection, :string # "rectangular" or "360"
      
      # Statistics
      add :view_count, :bigint
      add :like_count, :bigint
      add :comment_count, :bigint
      
      # Status
      add :privacy_status, :string # "public", "unlisted", "private"
      add :upload_status, :string # "processed", "uploaded", etc.
      add :embeddable, :boolean
      add :live_broadcast_content, :string # "none", "upcoming", "live"
      
      # Soft delete
      add :deleted_at, :utc_datetime
      
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:youtube_videos, [:tenant_id, :youtube_id])
    create index(:youtube_videos, [:tenant_id])
    create index(:youtube_videos, [:channel_id])
    create index(:youtube_videos, [:youtube_id])
    create index(:youtube_videos, [:published_at])
    create index(:youtube_videos, [:deleted_at])
    create index(:youtube_videos, [:live_broadcast_content])
  end
end
