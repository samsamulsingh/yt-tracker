defmodule YtTracker.Collections.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "collections" do
    field :name, :string
    field :description, :string
    field :auto_add_enabled, :boolean, default: false
    field :filters, :map, default: %{}
    field :metadata, :map, default: %{}

    belongs_to :tenant, YtTracker.Tenancy.Tenant
    many_to_many :videos, YtTracker.Videos.YoutubeVideo, join_through: "collection_videos"

    timestamps(type: :utc_datetime)
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:tenant_id, :name, :description, :auto_add_enabled, :filters, :metadata])
    |> validate_required([:tenant_id, :name])
  end
end
