defmodule YtTracker.Monitoring.ChannelMonitor do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "channel_monitors" do
    field :enabled, :boolean, default: true
    field :check_frequency_minutes, :integer, default: 15
    field :last_check_at, :utc_datetime
    field :next_check_at, :utc_datetime
    field :auto_add_to_collections, {:array, :binary_id}, default: []
    field :metadata, :map, default: %{}

    belongs_to :channel, YtTracker.Channels.YoutubeChannel

    timestamps(type: :utc_datetime)
  end

  def changeset(monitor, attrs) do
    monitor
    |> cast(attrs, [
      :channel_id,
      :enabled,
      :check_frequency_minutes,
      :last_check_at,
      :next_check_at,
      :auto_add_to_collections,
      :metadata
    ])
    |> validate_required([:channel_id])
    |> validate_number(:check_frequency_minutes, greater_than: 0)
    |> unique_constraint(:channel_id)
  end

  def schedule_next_check(monitor) do
    next_check =
      DateTime.utc_now()
      |> DateTime.add(monitor.check_frequency_minutes * 60, :second)

    changeset(monitor, %{next_check_at: next_check})
  end
end
