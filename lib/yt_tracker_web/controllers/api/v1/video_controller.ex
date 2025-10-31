defmodule YtTrackerWeb.Api.V1.VideoController do
  use YtTrackerWeb, :controller
  import YtTrackerWeb.ResponseHelpers

  alias YtTracker.Videos

  def refresh(conn, %{"video_ids" => video_ids}) when is_list(video_ids) do
    if length(video_ids) > 50 do
      render_error(conn, "too_many_videos", "Too Many Videos",
        "Maximum 50 video IDs allowed per request"
      )
    else
      case Videos.enrich_videos(video_ids) do
        {:ok, count} ->
          render_success(conn, %{
            message: "Videos enriched",
            count: count
          })

        {:error, reason} ->
          render_error(conn, "refresh_error", "Refresh Error",
            "Failed to refresh videos: #{inspect(reason)}"
          )
      end
    end
  end

  def refresh(conn, _params) do
    render_error(conn, "missing_parameter", "Missing Parameter",
      "video_ids array is required"
    )
  end
end
