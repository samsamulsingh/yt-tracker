defmodule YtTracker.Channels.SyncLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sync_logs" do
    field :sync_type, :string
    field :status, :string
    field :videos_fetched, :integer
    field :videos_new, :integer
    field :videos_updated, :integer
    field :error_message, :string
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :metadata, :map

    belongs_to :channel, YtTracker.Channels.YoutubeChannel

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(sync_log, attrs) do
    sync_log
    |> cast(attrs, [
      :channel_id,
      :sync_type,
      :status,
      :videos_fetched,
      :videos_new,
      :videos_updated,
      :error_message,
      :started_at,
      :completed_at,
      :metadata
    ])
    |> validate_required([:channel_id, :sync_type, :status, :started_at])
    |> validate_inclusion(:sync_type, ["api", "rss", "scraping"])
    |> validate_inclusion(:status, ["in_progress", "success", "failed"])
    |> validate_number(:videos_fetched, greater_than_or_equal_to: 0)
    |> validate_number(:videos_new, greater_than_or_equal_to: 0)
    |> validate_number(:videos_updated, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:channel_id)
  end
end
