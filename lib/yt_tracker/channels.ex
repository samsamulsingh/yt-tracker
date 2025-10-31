defmodule YtTracker.Channels do
  @moduledoc """
  The Channels context for managing YouTube channels.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Channels.YoutubeChannel
  alias YtTracker.Channels.SyncLog
  alias YtTracker.YoutubeApi
  alias YtTracker.Workers

  require Logger

  @doc """
  Lists all channels for a tenant.
  """
  def list_channels(tenant_id) do
    YoutubeChannel
    |> where(tenant_id: ^tenant_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single channel.
  """
  def get_channel!(tenant_id, id) do
    YoutubeChannel
    |> where(tenant_id: ^tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Gets a channel by ID (without tenant check).
  """
  def get_channel(id) do
    Repo.get(YoutubeChannel, id)
  end

  @doc """
  Gets a channel by YouTube ID.
  """
  def get_channel_by_youtube_id(tenant_id, youtube_id) do
    YoutubeChannel
    |> where(tenant_id: ^tenant_id, youtube_id: ^youtube_id)
    |> Repo.one()
  end

  @doc """
  Registers a new YouTube channel - fetches metadata from API and schedules backfill.
  """
  def register_channel(tenant_id, youtube_id) do
    case get_channel_by_youtube_id(tenant_id, youtube_id) do
      nil ->
        create_new_channel(tenant_id, youtube_id)

      channel ->
        {:ok, channel}
    end
  end

  defp create_new_channel(tenant_id, youtube_id) do
    with {:ok, channel_data} <- YoutubeApi.get_channel(youtube_id),
         {:ok, channel} <- create_channel(tenant_id, channel_data),
         {:ok, _job} <- schedule_backfill(channel) do
      {:ok, channel}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_channel(tenant_id, channel_data) do
    attrs =
      channel_data
      |> Map.put(:tenant_id, tenant_id)
      |> Map.put(:rss_url, YoutubeChannel.rss_url(channel_data.youtube_id))
      |> Map.put(:active, true)

    %YoutubeChannel{}
    |> YoutubeChannel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.
  """
  def update_channel(%YoutubeChannel{} = channel, attrs) do
    channel
    |> YoutubeChannel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a channel.
  """
  def delete_channel(%YoutubeChannel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Schedules a backfill job for a channel.
  """
  def schedule_backfill(%YoutubeChannel{} = channel) do
    %{channel_id: channel.id}
    |> Workers.BackfillChannel.new()
    |> Oban.insert()
  end

  @doc """
  Schedules an RSS poll job for a channel.
  """
  def schedule_poll(%YoutubeChannel{} = channel) do
    %{channel_id: channel.id}
    |> Workers.PollRss.new(queue: :rss)
    |> Oban.insert()
  end

  @doc """
  Updates RSS polling metadata.
  """
  def update_rss_metadata(%YoutubeChannel{} = channel, metadata) do
    now = DateTime.utc_now()

    attrs = %{
      rss_etag: metadata[:etag],
      rss_last_modified: metadata[:last_modified],
      last_polled_at: now
    }

    attrs =
      if metadata[:last_video_published_at] do
        Map.put(attrs, :last_video_published_at, metadata[:last_video_published_at])
      else
        attrs
      end

    update_channel(channel, attrs)
  end

  @doc """
  Lists channels that need RSS polling.
  """
  def list_channels_for_polling do
    stale_threshold = DateTime.add(DateTime.utc_now(), -15 * 60, :second)

    YoutubeChannel
    |> where([c], c.active == true)
    |> where([c], is_nil(c.last_polled_at) or c.last_polled_at < ^stale_threshold)
    |> limit(100)
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.
  """
  def change_channel(channel, attrs \\ %{}) do
    YoutubeChannel.changeset(channel, attrs)
  end

  @doc """
  Creates or gets an existing channel.
  """
  def create_or_get_channel(attrs) do
    tenant_id = attrs[:tenant_id] || attrs["tenant_id"]
    channel_id = attrs[:channel_id] || attrs["channel_id"]
    user_id = attrs[:user_id] || attrs["user_id"]

    case get_channel_by_youtube_id(tenant_id, channel_id) do
      nil ->
        # Try to fetch from API first
        case YoutubeApi.get_channel(channel_id) do
          {:ok, channel_data} ->
            Logger.info("Creating channel with data from YouTube API: #{inspect(channel_data)}")
            
            # IMPORTANT: Use the real channel ID from API response, not the input
            # The input could be a handle like "@username", but we need the UC channel ID
            real_channel_id = channel_data.youtube_id
            
            create_attrs =
              Map.merge(attrs, %{
                youtube_id: real_channel_id,
                title: channel_data.title,
                description: channel_data.description,
                thumbnail_url: channel_data.thumbnail_url,
                uploads_playlist_id: channel_data.uploads_playlist_id,
                subscriber_count: channel_data.subscriber_count,
                video_count: channel_data.video_count,
                view_count: channel_data.view_count,
                published_at: channel_data.published_at,
                custom_url: channel_data.custom_url,
                rss_url: YoutubeChannel.rss_url(real_channel_id),
                active: true
              })

            %YoutubeChannel{}
            |> YoutubeChannel.changeset(create_attrs)
            |> Repo.insert()

          {:error, reason} ->
            Logger.error("Failed to fetch channel from YouTube API: #{inspect(reason)}")
            # Fallback: create with just the ID
            %YoutubeChannel{}
            |> YoutubeChannel.changeset(%{
              tenant_id: tenant_id,
              youtube_id: channel_id,
              user_id: user_id,
              title: "Channel #{channel_id}",
              rss_url: YoutubeChannel.rss_url(channel_id),
              active: true
            })
            |> Repo.insert()
        end

      channel ->
        # Update user_id if provided and fetch missing data if needed
        if user_id do
          update_channel(channel, %{user_id: user_id})
        else
          {:ok, channel}
        end
    end
  end

  @doc """
  Enables monitoring for a channel.
  """
  def enable_monitoring(channel_id) do
    alias YtTracker.Channels.ChannelMonitor
    
    # Check if monitor already exists
    monitor =
      from(m in ChannelMonitor, where: m.channel_id == ^channel_id)
      |> Repo.one()
    
    case monitor do
      nil ->
        # Create new monitor
        %ChannelMonitor{}
        |> ChannelMonitor.changeset(%{
          channel_id: channel_id,
          enabled: true,
          check_frequency_minutes: 15
        })
        |> Repo.insert()
      
      existing ->
        # Update to enabled
        existing
        |> ChannelMonitor.changeset(%{enabled: true})
        |> Repo.update()
    end
  end

  @doc """
  Disables monitoring for a channel.
  """
  def disable_monitoring(channel_id) do
    alias YtTracker.Channels.ChannelMonitor
    
    monitor =
      from(m in ChannelMonitor, where: m.channel_id == ^channel_id)
      |> Repo.one()
    
    case monitor do
      nil ->
        {:ok, nil}
      
      existing ->
        existing
        |> ChannelMonitor.changeset(%{enabled: false})
        |> Repo.update()
    end
  end

  @doc """
  Updates the RSS check frequency for a channel monitor.
  """
  def update_monitor_frequency(channel_id, frequency_minutes) do
    alias YtTracker.Channels.ChannelMonitor
    
    monitor =
      from(m in ChannelMonitor, where: m.channel_id == ^channel_id)
      |> Repo.one()
    
    case monitor do
      nil ->
        # Create monitor if it doesn't exist
        %ChannelMonitor{}
        |> ChannelMonitor.changeset(%{
          channel_id: channel_id,
          enabled: true,
          check_frequency_minutes: frequency_minutes
        })
        |> Repo.insert()
      
      existing ->
        # Update frequency
        existing
        |> ChannelMonitor.changeset(%{check_frequency_minutes: frequency_minutes})
        |> Repo.update()
    end
  end

  @doc """
  Refreshes channel data from YouTube API.
  """
  def refresh_channel_data(%YoutubeChannel{} = channel) do
    case YoutubeApi.get_channel(channel.youtube_id) do
      {:ok, channel_data} ->
        Logger.info("Refreshing channel data from YouTube API: #{inspect(channel_data)}")
        
        # IMPORTANT: Use the real channel ID from API response
        # This fixes channels that were created with handles instead of UC channel IDs
        real_channel_id = channel_data.youtube_id
        
        update_attrs = %{
          youtube_id: real_channel_id,
          title: channel_data.title,
          description: channel_data.description,
          thumbnail_url: channel_data.thumbnail_url,
          uploads_playlist_id: channel_data.uploads_playlist_id,
          subscriber_count: channel_data.subscriber_count,
          video_count: channel_data.video_count,
          view_count: channel_data.view_count,
          published_at: channel_data.published_at,
          custom_url: channel_data.custom_url,
          rss_url: YoutubeChannel.rss_url(real_channel_id)
        }
        
        update_channel(channel, update_attrs)
      
      {:error, reason} ->
        Logger.error("Failed to refresh channel data: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ==================== Sync Log Functions ====================

  @doc """
  Creates a new sync log entry.
  """
  def create_sync_log(attrs) do
    %SyncLog{}
    |> SyncLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sync log entry.
  """
  def update_sync_log(%SyncLog{} = log, attrs) do
    log
    |> SyncLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Lists sync logs for a channel with pagination.
  """
  def list_sync_logs(channel_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    offset = (page - 1) * per_page

    query =
      from l in SyncLog,
        where: l.channel_id == ^channel_id,
        order_by: [desc: l.started_at],
        limit: ^per_page,
        offset: ^offset

    Repo.all(query)
  end

  @doc """
  Gets total count of sync logs for a channel.
  """
  def count_sync_logs(channel_id) do
    from(l in SyncLog, where: l.channel_id == ^channel_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Gets a single sync log.
  """
  def get_sync_log(id) do
    Repo.get(SyncLog, id)
  end
end
