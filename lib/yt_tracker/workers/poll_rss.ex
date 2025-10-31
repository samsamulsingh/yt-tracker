defmodule YtTracker.Workers.PollRss do
  @moduledoc """
  Polls YouTube RSS feeds for new videos and updates.
  Can be run as a cron job or on-demand for specific channels.
  """

  use Oban.Worker,
    queue: :rss,
    max_attempts: 3

  alias YtTracker.{Repo, Channels, Videos, RSS, Webhooks}
  alias YtTracker.Channels.YoutubeChannel

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"channel_id" => channel_id}}) do
    channel = Repo.get!(YoutubeChannel, channel_id)
    poll_channel(channel)
  end

  # Cron job - poll all stale channels
  def perform(%Oban.Job{args: _args}) do
    channels = Channels.list_channels_for_polling()

    Logger.info("Polling RSS feeds for #{length(channels)} channels")

    results =
      Enum.map(channels, fn channel ->
        poll_channel(channel)
      end)

    success_count = Enum.count(results, fn {:ok, _} -> true; _ -> false end)
    Logger.info("RSS polling completed: #{success_count}/#{length(channels)} successful")

    {:ok, %{total: length(channels), successful: success_count}}
  end

  defp poll_channel(channel) do
    Logger.debug("Polling RSS for channel #{channel.youtube_id}")

    # Create sync log entry
    {:ok, sync_log} = Channels.create_sync_log(%{
      channel_id: channel.id,
      sync_type: "rss",
      status: "in_progress",
      started_at: DateTime.utc_now(),
      videos_fetched: 0,
      videos_new: 0,
      videos_updated: 0
    })

    opts = [
      etag: channel.rss_etag,
      last_modified: channel.rss_last_modified
    ]

    case RSS.fetch_channel_feed(channel.youtube_id, opts) do
      {:ok, %{not_modified: true}} ->
        # Update last_polled_at even if not modified
        Channels.update_rss_metadata(channel, %{})
        
        # Update sync log
        Channels.update_sync_log(sync_log, %{
          status: "success",
          completed_at: DateTime.utc_now(),
          videos_fetched: 0,
          videos_new: 0,
          videos_updated: 0,
          metadata: %{not_modified: true}
        })
        
        {:ok, :not_modified}

      {:ok, %{videos: videos, etag: etag, last_modified: last_modified}} ->
        case process_feed_videos(channel, videos, etag, last_modified) do
          {:ok, %{total: total, new: new}} ->
            # Update sync log
            Channels.update_sync_log(sync_log, %{
              status: "success",
              completed_at: DateTime.utc_now(),
              videos_fetched: total,
              videos_new: new,
              videos_updated: total - new
            })
            
            {:ok, %{total: total, new: new}}
          
          error ->
            # Update sync log with error
            Channels.update_sync_log(sync_log, %{
              status: "failed",
              completed_at: DateTime.utc_now(),
              error_message: inspect(error)
            })
            
            error
        end

      {:error, reason} ->
        Logger.error("RSS polling failed for channel #{channel.youtube_id}: #{inspect(reason)}")
        
        # Update sync log with error
        Channels.update_sync_log(sync_log, %{
          status: "failed",
          completed_at: DateTime.utc_now(),
          error_message: inspect(reason)
        })
        
        {:error, reason}
    end
  end

  defp process_feed_videos(channel, videos, etag, last_modified) do
    # Get existing video IDs from database
    existing_in_db =
      Videos.list_videos(channel.id)
      |> Enum.map(& &1.youtube_id)
      |> MapSet.new()

    # Filter to only new videos not in database
    new_videos = Enum.filter(videos, fn video ->
      not MapSet.member?(existing_in_db, video.youtube_id)
    end)

    # Only insert new videos
    if length(new_videos) > 0 do
      videos_attrs =
        Enum.map(new_videos, fn video ->
          %{
            tenant_id: channel.tenant_id,
            channel_id: channel.id,
            youtube_id: video.youtube_id,
            title: video.title,
            published_at: video.published_at,
            thumbnail_url: video.thumbnail_url,
            source: "rss"
          }
        end)

      Videos.upsert_videos(videos_attrs)
      
      Logger.info("Inserted #{length(new_videos)} new videos for channel #{channel.youtube_id}")
    else
      Logger.debug("No new videos found for channel #{channel.youtube_id}")
    end

    # Update RSS metadata
    last_video_published_at =
      videos
      |> Enum.map(& &1.published_at)
      |> Enum.reject(&is_nil/1)
      |> Enum.max(DateTime, fn -> nil end)

    Channels.update_rss_metadata(channel, %{
      etag: etag,
      last_modified: last_modified,
      last_video_published_at: last_video_published_at
    })

    # Fire webhooks for new videos
    if length(new_videos) > 0 do
      new_video_ids = Enum.map(new_videos, & &1.youtube_id)
      
      Enum.each(new_video_ids, fn video_id ->
        fire_video_created_webhook(channel.tenant_id, video_id)
      end)

      # Schedule enrichment for new videos
      schedule_enrichment(new_video_ids)
    end

    {:ok, %{total: length(videos), new: length(new_videos)}}
  end

  defp fire_video_created_webhook(tenant_id, youtube_id) do
    case Videos.get_video_by_youtube_id(tenant_id, youtube_id) do
      nil ->
        :ok

      video ->
        Webhooks.fire_event(tenant_id, "video.created", %{
          video_id: video.id,
          youtube_id: video.youtube_id,
          title: video.title,
          published_at: video.published_at
        })
    end
  end

  defp schedule_enrichment(video_ids) when is_list(video_ids) and length(video_ids) > 0 do
    %{video_ids: video_ids}
    |> YtTracker.Workers.EnrichVideos.new(queue: :enrich)
    |> Oban.insert()
  end

  defp schedule_enrichment(_), do: :ok
end
