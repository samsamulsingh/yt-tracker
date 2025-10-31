defmodule YtTracker.IdempotencyKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "idempotency_keys" do
    field :idempotency_key, :string
    field :request_path, :string
    field :request_method, :string
    field :request_params, :map
    field :response_status, :integer
    field :response_body, :string
    field :created_at, :utc_datetime

    belongs_to :tenant, YtTracker.Tenancy.Tenant
  end

  @doc false
  def changeset(key, attrs) do
    key
    |> cast(attrs, [
      :tenant_id, :idempotency_key, :request_path, :request_method,
      :request_params, :response_status, :response_body, :created_at
    ])
    |> validate_required([:tenant_id, :idempotency_key, :request_path, :request_method])
    |> unique_constraint([:tenant_id, :idempotency_key])
  end
end
