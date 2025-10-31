defmodule YtTracker.Settings.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings" do
    field :key, :string
    field :value, :string
    field :encrypted_value, :binary
    field :description, :string

    belongs_to :tenant, YtTracker.Tenancy.Tenant
    belongs_to :user, YtTracker.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:key, :value, :encrypted_value, :description, :tenant_id, :user_id])
    |> validate_required([:key])
    |> unique_constraint([:key, :tenant_id])
  end
end
