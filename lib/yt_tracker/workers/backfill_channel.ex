defmodule YtTracker.Workers.BackfillChannel do
  @moduledoc """
  Backfills all videos for a YouTube channel using the uploads playlist.
  """

  use Oban.Worker,
    queue: :backfill,
    max_attempts: 3

  alias YtTracker.{Repo, Channels, Videos, YoutubeApi}
  alias YtTracker.Channels.YoutubeChannel

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"channel_id" => channel_id}}) do
    channel = Repo.get!(YoutubeChannel, channel_id)

    Logger.info("Starting backfill for channel #{channel.youtube_id}")
    
    # Create sync log entry
    {:ok, sync_log} = Channels.create_sync_log(%{
      channel_id: channel.id,
      sync_type: "api",
      status: "in_progress",
      started_at: DateTime.utc_now(),
      videos_fetched: 0,
      videos_new: 0,
      videos_updated: 0
    })
    
    # Broadcast initial status
    broadcast_progress(channel.id, "initializing", 0, 0)

    case backfill_channel(channel, sync_log) do
      {:ok, {video_count, new_count, updated_count}} ->
        Logger.info("Backfilled #{video_count} videos for channel #{channel.youtube_id} (#{new_count} new, #{updated_count} updated)")
        
        # Update sync log
        Channels.update_sync_log(sync_log, %{
          status: "success",
          completed_at: DateTime.utc_now(),
          videos_fetched: video_count,
          videos_new: new_count,
          videos_updated: updated_count
        })
        
        # Update last_api_sync_at timestamp
        channel
        |> YoutubeChannel.changeset(%{last_api_sync_at: DateTime.utc_now()})
        |> Repo.update()
        
        broadcast_complete(channel.id, video_count)
        schedule_enrichment(channel)
        {:ok, video_count}

      {:error, reason} ->
        Logger.error("Backfill failed for channel #{channel.youtube_id}: #{inspect(reason)}")
        
        # Update sync log with error
        Channels.update_sync_log(sync_log, %{
          status: "failed",
          completed_at: DateTime.utc_now(),
          error_message: inspect(reason)
        })
        
        broadcast_error(channel.id, inspect(reason))
        {:error, reason}
    end
  end

  defp backfill_channel(channel, sync_log) do
    if channel.uploads_playlist_id do
      fetch_all_videos(channel, sync_log, channel.uploads_playlist_id)
    else
      Logger.warning("Channel #{channel.youtube_id} has no uploads playlist")
      {:ok, {0, 0, 0}}
    end
  end

  defp fetch_all_videos(channel, sync_log, playlist_id, page_token \\ nil, acc \\ [], new_count \\ 0, updated_count \\ 0) do
    case YoutubeApi.list_playlist_items(playlist_id, page_token: page_token) do
      {:ok, %{items: items, next_page_token: next_token}} ->
        # Create minimal video records from playlist items
        videos =
          Enum.map(items, fn item ->
            %{
              tenant_id: channel.tenant_id,
              channel_id: channel.id,
              youtube_id: item.youtube_id,
              published_at: item.published_at,
              source: "api"
            }
          end)

        # Upsert videos and track new vs updated
        {batch_new, batch_updated} = Videos.upsert_videos_with_counts(videos)

        new_acc = acc ++ items
        current_count = length(new_acc)
        total_new = new_count + batch_new
        total_updated = updated_count + batch_updated
        
        # Broadcast progress update
        broadcast_progress(channel.id, "fetching", current_count, current_count)

        if next_token do
          fetch_all_videos(channel, sync_log, playlist_id, next_token, new_acc, total_new, total_updated)
        else
          {:ok, {length(new_acc), total_new, total_updated}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp broadcast_progress(channel_id, status, progress, total) do
    Phoenix.PubSub.broadcast(
      YtTracker.PubSub,
      "channel:#{channel_id}:sync",
      {:sync_progress, status, progress, total}
    )
  end

  defp broadcast_complete(channel_id, total_videos) do
    Phoenix.PubSub.broadcast(
      YtTracker.PubSub,
      "channel:#{channel_id}:sync",
      {:sync_complete, total_videos}
    )
  end

  defp broadcast_error(channel_id, reason) do
    Phoenix.PubSub.broadcast(
      YtTracker.PubSub,
      "channel:#{channel_id}:sync",
      {:sync_error, reason}
    )
  end

  defp schedule_enrichment(channel) do
    # Schedule enrichment for videos that don't have full metadata
    %{channel_id: channel.id}
    |> YtTracker.Workers.EnrichVideos.new(queue: :enrich)
    |> Oban.insert()
  end
end
