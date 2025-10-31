defmodule YtTracker.Webhooks.Endpoint do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_endpoints" do
    field :url, :string
    field :secret, :string
    field :active, :boolean, default: true
    field :events, {:array, :string}, default: ["*"]
    field :description, :string
    field :metadata, :map, default: %{}

    belongs_to :tenant, YtTracker.Tenancy.Tenant
    has_many :deliveries, YtTracker.Webhooks.Delivery, foreign_key: :endpoint_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(endpoint, attrs) do
    endpoint
    |> cast(attrs, [:tenant_id, :url, :secret, :active, :events, :description, :metadata])
    |> validate_required([:tenant_id, :url, :secret])
    |> validate_url(:url)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      uri = URI.parse(url)
      if uri.scheme in ["http", "https"] and uri.host do
        []
      else
        [{field, "must be a valid HTTP/HTTPS URL"}]
      end
    end)
  end

  @doc """
  Generates a webhook secret
  """
  def generate_secret do
    Base.encode32(:crypto.strong_rand_bytes(32), padding: false)
  end
end
