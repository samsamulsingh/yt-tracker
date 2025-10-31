defmodule YtTrackerWeb.Api.V1.ChannelController do
  use YtTrackerWeb, :controller
  import YtTrackerWeb.ResponseHelpers

  alias YtTracker.{Channels, Videos}

  def create(conn, %{"youtube_id" => youtube_id}) do
    tenant_id = conn.assigns.tenant_id

    case Channels.register_channel(tenant_id, youtube_id) do
      {:ok, channel} ->
        render_success(conn, serialize_channel(channel), status: :created)

      {:error, :not_found} ->
        render_error(conn, "channel_not_found", "Channel Not Found",
          "YouTube channel '#{youtube_id}' not found",
          status: :not_found
        )

      {:error, changeset} ->
        render_changeset_error(conn, changeset)
    end
  end

  def create(conn, _params) do
    render_error(conn, "missing_parameter", "Missing Parameter",
      "youtube_id is required"
    )
  end

  def index(conn, _params) do
    tenant_id = conn.assigns.tenant_id
    channels = Channels.list_channels(tenant_id)

    render_success(conn, Enum.map(channels, &serialize_channel/1))
  end

  def show(conn, %{"id" => id}) do
    tenant_id = conn.assigns.tenant_id

    # Try to find by youtube_id first, then by database id
    channel = case Channels.get_channel_by_youtube_id(tenant_id, id) do
      nil -> Channels.get_channel!(tenant_id, id)
      channel -> channel
    end

    case channel do
      nil ->
        render_error(conn, "not_found", "Not Found", "Channel not found", status: :not_found)

      channel ->
        render_success(conn, serialize_channel(channel))
    end
  end

  def backfill(conn, %{"id" => id}) do
    tenant_id = conn.assigns.tenant_id
    channel = Channels.get_channel!(tenant_id, id)

    case Channels.schedule_backfill(channel) do
      {:ok, _job} ->
        render_success(conn, %{
          message: "Backfill scheduled",
          channel_id: channel.id
        })

      {:error, reason} ->
        render_error(conn, "backfill_error", "Backfill Error",
          "Failed to schedule backfill: #{inspect(reason)}"
        )
    end
  end

  def poll(conn, %{"id" => id}) do
    tenant_id = conn.assigns.tenant_id
    channel = Channels.get_channel!(tenant_id, id)

    case Channels.schedule_poll(channel) do
      {:ok, _job} ->
        render_success(conn, %{
          message: "RSS poll scheduled",
          channel_id: channel.id
        })

      {:error, reason} ->
        render_error(conn, "poll_error", "Poll Error",
          "Failed to schedule poll: #{inspect(reason)}"
        )
    end
  end

  def videos(conn, %{"id" => id} = params) do
    tenant_id = conn.assigns.tenant_id
    
    # Try to find by youtube_id first, then by database id
    channel = case Channels.get_channel_by_youtube_id(tenant_id, id) do
      nil -> Channels.get_channel!(tenant_id, id)
      channel -> channel
    end

    case channel do
      nil ->
        render_error(conn, "not_found", "Not Found", "Channel not found", status: :not_found)
        
      channel ->
        opts = build_video_filters(params)
        videos = Videos.list_videos(channel.id, opts)

        render_success(conn, Enum.map(videos, &serialize_video/1), meta: %{count: length(videos)})
    end
  end

  defp build_video_filters(params) do
    []
    |> maybe_add_filter(:since, params["since"], &parse_datetime/1)
    |> maybe_add_filter(:until, params["until"], &parse_datetime/1)
    |> maybe_add_filter(:is_live, params["is_live"], &parse_boolean/1)
    |> maybe_add_filter(:search, params["search"], & &1)
    |> maybe_add_filter(:limit, params["limit"], &parse_integer/1)
  end

  defp maybe_add_filter(opts, _key, nil, _parser), do: opts
  defp maybe_add_filter(opts, _key, "", _parser), do: opts

  defp maybe_add_filter(opts, key, value, parser) do
    case parser.(value) do
      nil -> opts
      parsed -> Keyword.put(opts, key, parsed)
    end
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_boolean("true"), do: true
  defp parse_boolean("false"), do: false
  defp parse_boolean(_), do: nil

  defp parse_integer(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp parse_integer(int) when is_integer(int), do: int
  defp parse_integer(_), do: nil

  defp serialize_channel(channel) do
    %{
      id: channel.id,
      youtube_id: channel.youtube_id,
      title: channel.title,
      description: channel.description,
      custom_url: channel.custom_url,
      thumbnail_url: channel.thumbnail_url,
      uploads_playlist_id: channel.uploads_playlist_id,
      subscriber_count: channel.subscriber_count,
      video_count: channel.video_count,
      view_count: channel.view_count,
      published_at: channel.published_at,
      last_polled_at: channel.last_polled_at,
      last_video_published_at: channel.last_video_published_at,
      active: channel.active,
      inserted_at: channel.inserted_at,
      updated_at: channel.updated_at
    }
  end

  defp serialize_video(video) do
    %{
      id: video.id,
      youtube_id: video.youtube_id,
      title: video.title,
      description: video.description,
      published_at: video.published_at,
      thumbnail_url: video.thumbnail_url,
      duration: video.duration,
      duration_seconds: video.duration_seconds,
      view_count: video.view_count,
      like_count: video.like_count,
      comment_count: video.comment_count,
      live_broadcast_content: video.live_broadcast_content,
      inserted_at: video.inserted_at,
      updated_at: video.updated_at
    }
  end
end
