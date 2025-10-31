defmodule YtTracker.Tenancy.Tenant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tenants" do
    field :name, :string
    field :slug, :string
    field :active, :boolean, default: true
    field :metadata, :map, default: %{}

    has_many :youtube_channels, YtTracker.Channels.YoutubeChannel
    has_many :youtube_videos, YtTracker.Videos.YoutubeVideo
    has_many :api_keys, YtTracker.ApiAuth.ApiKey
    has_many :webhook_endpoints, YtTracker.Webhooks.Endpoint
    has_many :webhook_deliveries, YtTracker.Webhooks.Delivery

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug, :active, :metadata])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/,
      message: "must contain only lowercase letters, numbers, hyphens, and underscores"
    )
    |> unique_constraint(:slug)
  end
end
