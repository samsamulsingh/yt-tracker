defmodule YtTracker.ApiAuth.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "api_keys" do
    field :name, :string
    field :key_hash, :string
    field :key_prefix, :string
    field :active, :boolean, default: true
    field :rate_limit, :integer
    field :rate_window_seconds, :integer
    field :scopes, {:array, :string}, default: []
    field :last_used_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :tenant, YtTracker.Tenancy.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [
      :tenant_id, :name, :key_hash, :key_prefix, :active,
      :rate_limit, :rate_window_seconds, :scopes,
      :last_used_at, :expires_at, :metadata
    ])
    |> validate_required([:tenant_id, :name, :key_hash, :key_prefix])
    |> unique_constraint(:key_hash)
    |> unique_constraint(:key_prefix)
  end

  @doc """
  Generates a new API key and returns {key, prefix, hash}
  """
  def generate_key do
    key = "yttr_" <> Base.encode32(:crypto.strong_rand_bytes(32), padding: false)
    prefix = String.slice(key, 0, 12)
    hash = :crypto.hash(:sha256, key) |> Base.encode16(case: :lower)
    {key, prefix, hash}
  end
end
