defmodule YtTracker.Workers.EnrichVideos do
  @moduledoc """
  Enriches videos with full metadata from YouTube API.
  """

  use Oban.Worker,
    queue: :enrich,
    max_attempts: 3

  alias YtTracker.{Repo, Videos}
  alias YtTracker.Channels.YoutubeChannel
  alias YtTracker.Videos.YoutubeVideo

  import Ecto.Query

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"channel_id" => channel_id}}) do
    channel = Repo.get!(YoutubeChannel, channel_id)

    Logger.info("Starting enrichment for channel #{channel.youtube_id}")

    case enrich_channel_videos(channel) do
      {:ok, enriched_count} ->
        Logger.info("Enriched #{enriched_count} videos for channel #{channel.youtube_id}")
        {:ok, enriched_count}

      {:error, reason} ->
        Logger.error("Enrichment failed for channel #{channel.youtube_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def perform(%Oban.Job{args: %{"video_ids" => video_ids}}) when is_list(video_ids) do
    Logger.info("Enriching #{length(video_ids)} specific videos")

    case Videos.enrich_videos(video_ids) do
      {:ok, enriched_count} ->
        {:ok, enriched_count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp enrich_channel_videos(channel) do
    # Find videos that need enrichment (missing title or other metadata)
    video_ids =
      YoutubeVideo
      |> where(channel_id: ^channel.id)
      |> where([v], is_nil(v.deleted_at))
      |> where([v], is_nil(v.title) or is_nil(v.duration))
      |> select([v], v.youtube_id)
      |> limit(50)
      |> Repo.all()

    if length(video_ids) > 0 do
      Videos.enrich_videos(video_ids)
    else
      {:ok, 0}
    end
  end
end
