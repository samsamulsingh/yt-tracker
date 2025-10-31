defmodule YtTracker.Webhooks.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_deliveries" do
    field :event_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :attempt_count, :integer, default: 0
    field :max_attempts, :integer, default: 5
    field :next_attempt_at, :utc_datetime
    field :response_status, :integer
    field :response_body, :string
    field :error, :string
    field :sent_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :tenant, YtTracker.Tenancy.Tenant
    belongs_to :endpoint, YtTracker.Webhooks.Endpoint

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :tenant_id, :endpoint_id, :event_type, :payload, :status,
      :attempt_count, :max_attempts, :next_attempt_at,
      :response_status, :response_body, :error, :sent_at, :metadata
    ])
    |> validate_required([:tenant_id, :endpoint_id, :event_type, :payload, :status])
    |> validate_inclusion(:status, ["pending", "sent", "failed", "retrying"])
  end
end
