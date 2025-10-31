defmodule YtTracker.Videos.YoutubeVideo do
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
    
    field :duration, :string
    field :duration_seconds, :integer
    field :definition, :string
    field :dimension, :string
    field :caption, :string
    field :licensed_content, :boolean
    field :projection, :string
    
    field :view_count, :integer
    field :like_count, :integer
    field :comment_count, :integer
    
    field :privacy_status, :string
    field :upload_status, :string
    field :embeddable, :boolean
    field :live_broadcast_content, :string
    
    field :deleted_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :tenant, YtTracker.Tenancy.Tenant
    belongs_to :channel, YtTracker.Channels.YoutubeChannel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :tenant_id, :channel_id, :youtube_id, :title, :description,
      :published_at, :thumbnail_url, :duration, :duration_seconds,
      :definition, :dimension, :caption, :licensed_content,
      :projection, :view_count, :like_count, :comment_count,
      :privacy_status, :upload_status, :embeddable,
      :live_broadcast_content, :deleted_at, :metadata
    ])
    |> validate_required([:tenant_id, :channel_id, :youtube_id])
    |> unique_constraint([:tenant_id, :youtube_id])
  end
end
