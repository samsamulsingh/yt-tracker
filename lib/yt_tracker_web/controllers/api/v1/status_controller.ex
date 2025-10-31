defmodule YtTrackerWeb.Api.V1.StatusController do
  use YtTrackerWeb, :controller
  import YtTrackerWeb.ResponseHelpers

  def show(conn, _params) do
    render_success(conn, %{
      status: "ok",
      version: "1.0.0",
      timestamp: DateTime.utc_now()
    })
  end
end
