defmodule YtTracker.Videos do
  @moduledoc """
  The Videos context for managing YouTube videos.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Videos.YoutubeVideo
  alias YtTracker.Channels.YoutubeChannel

  require Logger

  @doc """
  Lists videos for a channel with optional filters.
  """
  def list_videos(channel_id, opts \\ []) do
    query =
      YoutubeVideo
      |> where(channel_id: ^channel_id)
      |> where([v], is_nil(v.deleted_at))

    query
    |> apply_filters(opts)
    |> order_by(desc: :published_at)
    |> limit_query(opts)
    |> Repo.all()
  end

  @doc """
  Lists videos for a tenant with optional filters.
  """
  def list_videos_by_tenant(tenant_id, opts \\ []) do
    query =
      YoutubeVideo
      |> where(tenant_id: ^tenant_id)
      |> where([v], is_nil(v.deleted_at))

    query
    |> apply_filters(opts)
    |> order_by(desc: :published_at)
    |> limit_query(opts)
    |> Repo.all()
  end

  @doc """
  Lists recent videos for a tenant.
  """
  def list_recent_videos(tenant_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    list_videos_by_tenant(tenant_id, limit: limit)
  end

  @doc """
  Gets a single video.
  """
  def get_video!(tenant_id, id) do
    YoutubeVideo
    |> where(tenant_id: ^tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Gets a video by YouTube ID.
  """
  def get_video_by_youtube_id(tenant_id, youtube_id) do
    YoutubeVideo
    |> where(tenant_id: ^tenant_id, youtube_id: ^youtube_id)
    |> where([v], is_nil(v.deleted_at))
    |> Repo.one()
  end

  @doc """
  Upserts a video (insert or update based on tenant_id + youtube_id).
  """
  def upsert_video(attrs) do
    tenant_id = attrs[:tenant_id] || attrs["tenant_id"]
    youtube_id = attrs[:youtube_id] || attrs["youtube_id"]

    result =
      case get_video_by_youtube_id(tenant_id, youtube_id) do
        nil ->
          %YoutubeVideo{}
          |> YoutubeVideo.changeset(attrs)
          |> Repo.insert()

        video ->
          video
          |> YoutubeVideo.changeset(Map.put(attrs, :deleted_at, nil))
          |> Repo.update()
      end

    # Broadcast video creation for LiveView
    case result do
      {:ok, video} ->
        Phoenix.PubSub.broadcast(
          YtTracker.PubSub,
          "videos:updates",
          {:video_created, video}
        )

        {:ok, video}

      error ->
        error
    end
  end

  @doc """
  Batch upsert videos.
  """
  def upsert_videos(videos_attrs) when is_list(videos_attrs) do
    Enum.map(videos_attrs, &upsert_video/1)
  end

  @doc """
  Batch upsert videos and return counts of new vs updated.
  """
  def upsert_videos_with_counts(videos_attrs) when is_list(videos_attrs) do
    results = Enum.map(videos_attrs, fn attrs ->
      tenant_id = attrs[:tenant_id] || attrs["tenant_id"]
      youtube_id = attrs[:youtube_id] || attrs["youtube_id"]
      
      case get_video_by_youtube_id(tenant_id, youtube_id) do
        nil ->
          case %YoutubeVideo{} |> YoutubeVideo.changeset(attrs) |> Repo.insert() do
            {:ok, _} -> :new
            _ -> :error
          end
        
        video ->
          case video |> YoutubeVideo.changeset(Map.put(attrs, :deleted_at, nil)) |> Repo.update() do
            {:ok, _} -> :updated
            _ -> :error
          end
      end
    end)
    
    new_count = Enum.count(results, &(&1 == :new))
    updated_count = Enum.count(results, &(&1 == :updated))
    
    {new_count, updated_count}
  end

  @doc """
  Soft-deletes videos not in the given list of YouTube IDs.
  """
  def mark_missing_videos_deleted(channel_id, existing_youtube_ids) do
    now = DateTime.utc_now()

    YoutubeVideo
    |> where(channel_id: ^channel_id)
    |> where([v], v.youtube_id not in ^existing_youtube_ids)
    |> where([v], is_nil(v.deleted_at))
    |> Repo.update_all(set: [deleted_at: now])
  end

  @doc """
  Enriches videos with full metadata from YouTube API.
  """
  def enrich_videos(video_ids) when is_list(video_ids) do
    case YtTracker.YoutubeApi.get_videos(video_ids) do
      {:ok, videos_data} ->
        Enum.each(videos_data, fn video_data ->
          # Find existing video and update it
          case Repo.get_by(YoutubeVideo, youtube_id: video_data.youtube_id) do
            nil ->
              Logger.warning("Video #{video_data.youtube_id} not found for enrichment")

            video ->
              video
              |> YoutubeVideo.changeset(video_data)
              |> Repo.update()
          end
        end)

        {:ok, length(videos_data)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:since, datetime}, q ->
        where(q, [v], v.published_at >= ^datetime)

      {:until, datetime}, q ->
        where(q, [v], v.published_at <= ^datetime)

      {:is_live, true}, q ->
        where(q, [v], v.live_broadcast_content in ["live", "upcoming"])

      {:is_live, false}, q ->
        where(q, [v], v.live_broadcast_content == "none")

      {:search, term}, q ->
        search_term = "%#{term}%"
        where(q, [v], ilike(v.title, ^search_term) or ilike(v.description, ^search_term))

      _other, q ->
        q
    end)
  end

  defp limit_query(query, opts) do
    case Keyword.get(opts, :limit) do
      nil -> query
      limit -> limit(query, ^limit)
    end
  end
end
