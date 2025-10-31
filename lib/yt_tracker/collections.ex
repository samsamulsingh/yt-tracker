defmodule YtTracker.Collections do
  @moduledoc """
  The Collections context for managing video collections.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Collections.Collection
  alias YtTracker.Videos.YoutubeVideo

  @doc """
  Lists all collections for a tenant.
  """
  def list_collections(tenant_id) do
    Collection
    |> where(tenant_id: ^tenant_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single collection with videos preloaded.
  """
  def get_collection!(tenant_id, id) do
    Collection
    |> where(tenant_id: ^tenant_id)
    |> Repo.get!(id)
    |> Repo.preload(:videos)
  end

  @doc """
  Creates a collection.
  """
  def create_collection(attrs \\ %{}) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection.
  """
  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection.
  """
  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  @doc """
  Adds a video to a collection.
  """
  def add_video_to_collection(collection_id, video_id, added_by \\ "manual") do
    now = DateTime.utc_now()

    Repo.insert(
      %{
        id: Ecto.UUID.generate(),
        collection_id: collection_id,
        video_id: video_id,
        added_at: now,
        added_by: added_by
      },
      into: "collection_videos",
      on_conflict: :nothing
    )
  end

  @doc """
  Removes a video from a collection.
  """
  def remove_video_from_collection(collection_id, video_id) do
    from(cv in "collection_videos",
      where: cv.collection_id == ^collection_id and cv.video_id == ^video_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Lists videos in a collection.
  """
  def list_collection_videos(collection_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    query =
      from v in YoutubeVideo,
        join: cv in "collection_videos",
        on: cv.video_id == v.id,
        where: cv.collection_id == ^collection_id,
        where: is_nil(v.deleted_at),
        order_by: [desc: cv.added_at],
        limit: ^limit,
        select: v

    Repo.all(query)
  end

  @doc """
  Auto-adds a video to collections based on filters.
  """
  def auto_add_video_to_collections(video) do
    # Get all collections with auto_add enabled
    collections =
      Collection
      |> where(tenant_id: ^video.tenant_id, auto_add_enabled: true)
      |> Repo.all()

    Enum.each(collections, fn collection ->
      if video_matches_filters?(video, collection.filters) do
        add_video_to_collection(collection.id, video.id, "auto")
      end
    end)
  end

  defp video_matches_filters?(_video, filters) when filters == %{}, do: true

  defp video_matches_filters?(video, filters) do
    Enum.all?(filters, fn
      {"min_views", min} -> (video.view_count || 0) >= min
      {"max_views", max} -> (video.view_count || 0) <= max
      {"is_live", true} -> video.live_broadcast_content in ["live", "upcoming"]
      {"is_live", false} -> video.live_broadcast_content == "none"
      {"keyword", keyword} -> String.contains?(String.downcase(video.title || ""), String.downcase(keyword))
      _ -> true
    end)
  end
end
