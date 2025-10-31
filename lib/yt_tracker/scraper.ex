defmodule YtTracker.Scraper do
  @moduledoc """
  YouTube scraping fallback for when API quota is exhausted.
  Uses RSS feeds and HTML parsing.
  """

  require Logger

  @doc """
  Scrapes recent videos from a channel using RSS feed.
  """
  def scrape_channel_rss(channel_id) do
    url = "https://www.youtube.com/feeds/videos.xml?channel_id=#{channel_id}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        parse_rss_feed(body)

      {:ok, %{status: status}} ->
        Logger.warning("RSS feed returned status: #{status}")
        {:error, :http_error}

      {:error, reason} ->
        Logger.error("Failed to fetch RSS: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_rss_feed(xml_body) do
    try do
      import SweetXml

      videos =
        xml_body
        |> xpath(~x"//entry"l,
          video_id: ~x"./yt:videoId/text()"s,
          title: ~x"./title/text()"s,
          published_at: ~x"./published/text()"s,
          description: ~x"./media:group/media:description/text()"s,
          thumbnail_url: ~x"./media:group/media:thumbnail/@url"s
        )
        |> Enum.map(fn video ->
          %{
            video_id: video.video_id,
            title: video.title,
            description: video.description,
            published_at: parse_datetime(video.published_at),
            thumbnail_url: video.thumbnail_url
          }
        end)

      {:ok, videos}
    rescue
      e ->
        Logger.error("Failed to parse RSS XML: #{inspect(e)}")
        {:error, :parse_error}
    end
  end

  @doc """
  Scrapes channel information from the channel page.
  Fallback when API is unavailable.
  """
  def scrape_channel_info(channel_id) do
    url = "https://www.youtube.com/channel/#{channel_id}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        parse_channel_page(body)

      {:ok, %{status: status}} ->
        Logger.warning("Channel page returned status: #{status}")
        {:error, :http_error}

      {:error, reason} ->
        Logger.error("Failed to fetch channel page: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_channel_page(html) do
    try do
      # Parse with Floki
      document = Floki.parse_document!(html)

      # Extract channel name from meta tags
      title =
        document
        |> Floki.find("meta[property='og:title']")
        |> Floki.attribute("content")
        |> List.first()

      description =
        document
        |> Floki.find("meta[property='og:description']")
        |> Floki.attribute("content")
        |> List.first()

      thumbnail =
        document
        |> Floki.find("meta[property='og:image']")
        |> Floki.attribute("content")
        |> List.first()

      if title do
        {:ok,
         %{
           title: title,
           description: description || "",
           thumbnail_url: thumbnail
         }}
      else
        {:error, :channel_not_found}
      end
    rescue
      e ->
        Logger.error("Failed to parse channel page: #{inspect(e)}")
        {:error, :parse_error}
    end
  end

  @doc """
  Scrapes video statistics from the video page.
  """
  def scrape_video_stats(video_id) do
    url = "https://www.youtube.com/watch?v=#{video_id}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        parse_video_page(body)

      {:ok, %{status: status}} ->
        Logger.warning("Video page returned status: #{status}")
        {:error, :http_error}

      {:error, reason} ->
        Logger.error("Failed to fetch video page: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_video_page(html) do
    try do
      document = Floki.parse_document!(html)

      # Extract from meta tags
      title =
        document
        |> Floki.find("meta[property='og:title']")
        |> Floki.attribute("content")
        |> List.first()

      # Try to find view count in the page
      # Note: YouTube's structure changes frequently, this is a basic example
      {:ok,
       %{
         title: title,
         # Add more fields as needed based on what's available in the HTML
         scraped_at: DateTime.utc_now()
       }}
    rescue
      e ->
        Logger.error("Failed to parse video page: #{inspect(e)}")
        {:error, :parse_error}
    end
  end

  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end
end
