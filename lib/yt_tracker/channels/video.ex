defmodule YtTracker.Channels.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "youtube_videos" do
    field :youtube_id, :string
    field :title, :string
    field :description, :string
    field :published_at, :utc_datetime
    field :thumbnail_url, :string
    
    # Video metadata
    field :duration, :string
    field :duration_seconds, :integer
    field :definition, :string
    field :dimension, :string
    field :caption, :string
    field :licensed_content, :boolean
    field :projection, :string
    
    # Statistics
    field :view_count, :integer
    field :like_count, :integer
    field :comment_count, :integer
    
    # Status
    field :privacy_status, :string
    field :upload_status, :string
    field :embeddable, :boolean
    field :live_broadcast_content, :string
    
    # Source tracking
    field :source, :string, default: "api" # api, rss, or scraping
    
    # Soft delete
    field :deleted_at, :utc_datetime
    
    field :metadata, :map

    belongs_to :tenant, YtTracker.Tenants.Tenant
    belongs_to :channel, YtTracker.Channels.YoutubeChannel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :youtube_id, :title, :description, :published_at, :thumbnail_url,
      :duration, :duration_seconds, :definition, :dimension, :caption,
      :licensed_content, :projection, :view_count, :like_count, :comment_count,
      :privacy_status, :upload_status, :embeddable, :live_broadcast_content,
      :source, :deleted_at, :metadata, :tenant_id, :channel_id
    ])
    |> validate_required([:youtube_id, :tenant_id, :channel_id])
    |> validate_inclusion(:source, ["api", "rss", "scraping"])
    |> unique_constraint([:tenant_id, :youtube_id])
  end
end
