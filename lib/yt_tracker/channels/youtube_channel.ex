defmodule YtTracker.Channels.YoutubeChannel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "youtube_channels" do
    field :youtube_id, :string
    field :title, :string
    field :description, :string
    field :custom_url, :string
    field :thumbnail_url, :string
    field :uploads_playlist_id, :string
    field :subscriber_count, :integer
    field :video_count, :integer
    field :view_count, :integer
    field :published_at, :utc_datetime
    
    field :rss_url, :string
    field :rss_etag, :string
    field :rss_last_modified, :string
    field :last_polled_at, :utc_datetime
    field :last_video_published_at, :utc_datetime
    field :last_api_sync_at, :utc_datetime
    
    field :websub_subscribed, :boolean, default: false
    field :websub_expires_at, :utc_datetime
    field :websub_secret, :string
    
    field :active, :boolean, default: true
    field :metadata, :map, default: %{}

    belongs_to :tenant, YtTracker.Tenancy.Tenant
    belongs_to :user, YtTracker.Accounts.User
    has_many :youtube_videos, YtTracker.Videos.YoutubeVideo, foreign_key: :channel_id
    has_one :monitor, YtTracker.Channels.ChannelMonitor, foreign_key: :channel_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [
      :tenant_id, :user_id, :youtube_id, :title, :description, :custom_url,
      :thumbnail_url, :uploads_playlist_id, :subscriber_count,
      :video_count, :view_count, :published_at, :rss_url,
      :rss_etag, :rss_last_modified, :last_polled_at,
      :last_video_published_at, :last_api_sync_at, :websub_subscribed, :websub_expires_at,
      :websub_secret, :active, :metadata
    ])
    |> validate_required([:tenant_id, :youtube_id])
    |> unique_constraint([:tenant_id, :youtube_id])
  end

  def rss_url(youtube_id) do
    # RSS feeds only work with actual channel IDs (UCxxx format)
    # If a handle is stored, this will return an incorrect URL
    # The youtube_id should always be the actual channel ID from the API
    "https://www.youtube.com/feeds/videos.xml?channel_id=#{youtube_id}"
  end
end
