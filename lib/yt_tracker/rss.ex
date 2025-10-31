defmodule YtTracker.RSS do
  @moduledoc """
  Fetches and parses YouTube RSS feeds.
  """

  require Logger
  import SweetXml

  @doc """
  Fetches and parses the RSS feed for a YouTube channel.
  Returns {:ok, result} where result contains videos and cache headers.
  """
  def fetch_channel_feed(channel_id, opts \\ []) do
    url = "https://www.youtube.com/feeds/videos.xml?channel_id=#{channel_id}"
    etag = Keyword.get(opts, :etag)
    last_modified = Keyword.get(opts, :last_modified)

    headers = build_cache_headers(etag, last_modified)

    case Req.get(url, headers: headers) do
      {:ok, %{status: 304}} ->
        # Not modified
        {:ok, %{videos: [], not_modified: true}}

      {:ok, %{status: 200, body: body, headers: response_headers}} ->
        videos = parse_feed(body)

        result = %{
          videos: videos,
          not_modified: false,
          etag: get_header(response_headers, "etag"),
          last_modified: get_header(response_headers, "last-modified")
        }

        {:ok, result}

      {:ok, %{status: status}} ->
        Logger.warning("RSS feed returned status #{status} for channel #{channel_id}")
        {:error, {:http_error, status}}

      {:error, error} ->
        Logger.error("Failed to fetch RSS feed for channel #{channel_id}: #{inspect(error)}")
        {:error, error}
    end
  end

  # Private functions

  defp build_cache_headers(etag, last_modified) do
    []
    |> maybe_add_header("if-none-match", etag)
    |> maybe_add_header("if-modified-since", last_modified)
  end

  defp maybe_add_header(headers, _key, nil), do: headers
  defp maybe_add_header(headers, key, value), do: [{key, value} | headers]

  defp get_header(headers, key) do
    headers
    |> Enum.find(fn {k, _v} -> String.downcase(to_string(k)) == key end)
    |> case do
      {_k, v} -> List.to_string(v)
      nil -> nil
    end
  end

  defp parse_feed(xml) do
    xml
    |> xpath(~x"//entry"l,
      youtube_id: ~x"./yt:videoId/text()"s,
      title: ~x"./title/text()"s,
      published_at: ~x"./published/text()"s,
      updated_at: ~x"./updated/text()"s,
      author: ~x"./author/name/text()"s,
      thumbnail_url: ~x"./media:group/media:thumbnail/@url"s
    )
    |> Enum.map(&parse_entry/1)
  end

  defp parse_entry(entry) do
    %{
      youtube_id: entry.youtube_id,
      title: entry.title,
      published_at: parse_datetime(entry.published_at),
      thumbnail_url: entry.thumbnail_url
    }
  end

  defp parse_datetime(str) when is_binary(str) and str != "" do
    case DateTime.from_iso8601(str) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end

  defp parse_datetime(_), do: nil
end
