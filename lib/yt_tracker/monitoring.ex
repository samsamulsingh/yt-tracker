defmodule YtTracker.Monitoring do
  @moduledoc """
  The Monitoring context for automated channel monitoring.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Monitoring.ChannelMonitor
  alias YtTracker.{Channels, Collections}

  @doc """
  Gets or creates a monitor for a channel.
  """
  def get_or_create_monitor(channel_id, attrs \\ %{}) do
    case Repo.get_by(ChannelMonitor, channel_id: channel_id) do
      nil ->
        create_monitor(Map.put(attrs, :channel_id, channel_id))

      monitor ->
        {:ok, monitor}
    end
  end

  @doc """
  Creates a channel monitor.
  """
  def create_monitor(attrs \\ %{}) do
    %ChannelMonitor{}
    |> ChannelMonitor.changeset(attrs)
    |> ChannelMonitor.schedule_next_check()
    |> Repo.insert()
  end

  @doc """
  Updates a channel monitor.
  """
  def update_monitor(%ChannelMonitor{} = monitor, attrs) do
    monitor
    |> ChannelMonitor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Lists all active monitors that need checking.
  """
  def list_monitors_due_for_check do
    now = DateTime.utc_now()

    ChannelMonitor
    |> where([m], m.enabled == true)
    |> where([m], is_nil(m.next_check_at) or m.next_check_at <= ^now)
    |> Repo.all()
    |> Repo.preload(:channel)
  end

  @doc """
  Processes a monitor check - polls RSS and auto-adds to collections.
  """
  def process_monitor_check(%ChannelMonitor{} = monitor) do
    channel = Repo.preload(monitor, :channel).channel

    # Poll the RSS feed
    case Channels.schedule_poll(channel) do
      {:ok, _job} ->
        # Update monitor with last check time
        now = DateTime.utc_now()

        monitor
        |> ChannelMonitor.changeset(%{last_check_at: now})
        |> ChannelMonitor.schedule_next_check()
        |> Repo.update()

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Enables monitoring for a channel.
  """
  def enable_monitoring(channel_id, opts \\ []) do
    frequency = Keyword.get(opts, :frequency_minutes, 15)
    collections = Keyword.get(opts, :auto_add_to_collections, [])

    attrs = %{
      channel_id: channel_id,
      enabled: true,
      check_frequency_minutes: frequency,
      auto_add_to_collections: collections
    }

    case get_or_create_monitor(channel_id, attrs) do
      {:ok, monitor} ->
        update_monitor(monitor, Map.merge(attrs, %{enabled: true}))

      error ->
        error
    end
  end

  @doc """
  Disables monitoring for a channel.
  """
  def disable_monitoring(channel_id) do
    case Repo.get_by(ChannelMonitor, channel_id: channel_id) do
      nil ->
        {:ok, nil}

      monitor ->
        update_monitor(monitor, %{enabled: false})
    end
  end

  @doc """
  Processes a new video through monitoring rules.
  """
  def process_new_video(video) do
    # Get all monitors for this channel
    case Repo.get_by(ChannelMonitor, channel_id: video.channel_id) do
      nil ->
        :ok

      monitor ->
        # Auto-add to configured collections
        Enum.each(monitor.auto_add_to_collections, fn collection_id ->
          Collections.add_video_to_collection(collection_id, video.id, "auto")
        end)

        # Also check collection filters
        Collections.auto_add_video_to_collections(video)
    end
  end
end
