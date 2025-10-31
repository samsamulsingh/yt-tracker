defmodule YtTracker.Repo.Migrations.AddSourceToVideos do
  use Ecto.Migration

  def change do
    alter table(:youtube_videos) do
      add :source, :string, default: "api", comment: "How the video was synced: api, rss, or scraping"
    end

    create index(:youtube_videos, [:source])
  end
end
