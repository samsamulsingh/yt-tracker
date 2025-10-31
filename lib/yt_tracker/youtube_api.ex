defmodule YtTracker.YoutubeApi do
  @moduledoc """
  Client for YouTube Data API v3.
  """

  require Logger

  @base_url "https://www.googleapis.com/youtube/v3"

  @doc """
  Fetches channel information by channel ID or handle.
  """
  def get_channel(channel_id_or_handle) do
    with {:ok, key} <- api_key() do
      # Determine if it's a handle or channel ID
      params = if String.starts_with?(channel_id_or_handle, "@") or not String.starts_with?(channel_id_or_handle, "UC") do
        # It's a handle (with or without @)
        handle = String.trim_leading(channel_id_or_handle, "@")
        [
          part: "snippet,contentDetails,statistics",
          forHandle: handle,
          key: key
        ]
      else
        # It's a channel ID
        [
          part: "snippet,contentDetails,statistics",
          id: channel_id_or_handle,
          key: key
        ]
      end

      case Req.get("#{@base_url}/channels", params: params) do
        {:ok, %{status: 200, body: %{"items" => [item | _]}}} ->
          {:ok, parse_channel(item)}

        {:ok, %{status: 200, body: %{"items" => []}}} ->
          {:error, :not_found}

        {:ok, %{status: status, body: body}} ->
          Logger.error("YouTube API error: #{status} - #{inspect(body)}")
          {:error, {:api_error, status, body}}

        {:error, error} ->
          Logger.error("YouTube API request failed: #{inspect(error)}")
          {:error, error}
      end
    else
      {:error, :api_key_not_configured} ->
        Logger.warning("YouTube API key not configured, using fallback mode")
        {:error, :api_key_not_configured}
    end
  end

  @doc """
  Lists videos from a playlist (e.g., uploads playlist).
  """
  def list_playlist_items(playlist_id, opts \\ []) do
    with {:ok, key} <- api_key() do
      page_token = Keyword.get(opts, :page_token)
      max_results = Keyword.get(opts, :max_results, 50)

      params =
        [
          part: "snippet,contentDetails",
          playlistId: playlist_id,
          maxResults: max_results,
          key: key
        ]
        |> maybe_add_page_token(page_token)

      case Req.get("#{@base_url}/playlistItems", params: params) do
        {:ok, %{status: 200, body: body}} ->
          items = Enum.map(body["items"] || [], &parse_playlist_item/1)
          {:ok, %{items: items, next_page_token: body["nextPageToken"]}}

        {:ok, %{status: status, body: body}} ->
          Logger.error("YouTube API error: #{status} - #{inspect(body)}")
          {:error, {:api_error, status, body}}

        {:error, error} ->
          Logger.error("YouTube API request failed: #{inspect(error)}")
          {:error, error}
      end
    else
      {:error, :api_key_not_configured} ->
        Logger.warning("YouTube API key not configured")
        {:error, :api_key_not_configured}
    end
  end

  @doc """
  Fetches video details by video IDs (up to 50 at a time).
  """
  def get_videos(video_ids) when is_list(video_ids) do
    with {:ok, key} <- api_key() do
      video_ids_str = Enum.join(video_ids, ",")

      case Req.get("#{@base_url}/videos",
             params: [
               part: "snippet,contentDetails,statistics,status",
               id: video_ids_str,
               key: key
             ]
           ) do
        {:ok, %{status: 200, body: %{"items" => items}}} ->
          {:ok, Enum.map(items, &parse_video/1)}

        {:ok, %{status: status, body: body}} ->
          Logger.error("YouTube API error: #{status} - #{inspect(body)}")
          {:error, {:api_error, status, body}}

        {:error, error} ->
          Logger.error("YouTube API request failed: #{inspect(error)}")
          {:error, error}
      end
    else
      {:error, :api_key_not_configured} ->
        Logger.warning("YouTube API key not configured")
        {:error, :api_key_not_configured}
    end
  end

  # Private functions

  defp api_key do
    case Application.get_env(:yt_tracker, :youtube_api_key) do
      nil -> {:error, :api_key_not_configured}
      "" -> {:error, :api_key_not_configured}
      "YOUR_API_KEY_HERE" -> {:error, :api_key_not_configured}
      key -> {:ok, key}
    end
  end

  defp maybe_add_page_token(params, nil), do: params
  defp maybe_add_page_token(params, token), do: [{:pageToken, token} | params]

  defp parse_channel(item) do
    %{
      youtube_id: item["id"],
      title: get_in(item, ["snippet", "title"]),
      description: get_in(item, ["snippet", "description"]),
      custom_url: get_in(item, ["snippet", "customUrl"]),
      thumbnail_url: get_in(item, ["snippet", "thumbnails", "high", "url"]),
      uploads_playlist_id: get_in(item, ["contentDetails", "relatedPlaylists", "uploads"]),
      subscriber_count: parse_integer(get_in(item, ["statistics", "subscriberCount"])),
      video_count: parse_integer(get_in(item, ["statistics", "videoCount"])),
      view_count: parse_integer(get_in(item, ["statistics", "viewCount"])),
      published_at: parse_datetime(get_in(item, ["snippet", "publishedAt"]))
    }
  end

  defp parse_playlist_item(item) do
    %{
      youtube_id: get_in(item, ["contentDetails", "videoId"]),
      published_at: parse_datetime(get_in(item, ["contentDetails", "videoPublishedAt"]))
    }
  end

  defp parse_video(item) do
    %{
      youtube_id: item["id"],
      title: get_in(item, ["snippet", "title"]),
      description: get_in(item, ["snippet", "description"]),
      published_at: parse_datetime(get_in(item, ["snippet", "publishedAt"])),
      thumbnail_url: get_in(item, ["snippet", "thumbnails", "high", "url"]),
      duration: get_in(item, ["contentDetails", "duration"]),
      duration_seconds: parse_duration(get_in(item, ["contentDetails", "duration"])),
      definition: get_in(item, ["contentDetails", "definition"]),
      dimension: get_in(item, ["contentDetails", "dimension"]),
      caption: get_in(item, ["contentDetails", "caption"]),
      licensed_content: get_in(item, ["contentDetails", "licensedContent"]),
      projection: get_in(item, ["contentDetails", "projection"]),
      view_count: parse_integer(get_in(item, ["statistics", "viewCount"])),
      like_count: parse_integer(get_in(item, ["statistics", "likeCount"])),
      comment_count: parse_integer(get_in(item, ["statistics", "commentCount"])),
      privacy_status: get_in(item, ["status", "privacyStatus"]),
      upload_status: get_in(item, ["status", "uploadStatus"]),
      embeddable: get_in(item, ["status", "embeddable"]),
      live_broadcast_content: get_in(item, ["snippet", "liveBroadcastContent"])
    }
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(str) when is_binary(str), do: String.to_integer(str)
  defp parse_integer(int) when is_integer(int), do: int

  defp parse_datetime(nil), do: nil

  defp parse_datetime(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end

  defp parse_duration(nil), do: nil

  defp parse_duration(duration) when is_binary(duration) do
    # Parse ISO 8601 duration (e.g., "PT15M33S" -> 933 seconds)
    # Simple regex-based parser
    regex = ~r/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/
    case Regex.run(regex, duration) do
      [_, h, m, s] ->
        hours = if h != "", do: String.to_integer(h), else: 0
        minutes = if m != "", do: String.to_integer(m), else: 0
        seconds = if s != "", do: String.to_integer(s), else: 0
        hours * 3600 + minutes * 60 + seconds

      _ ->
        nil
    end
  end
end
