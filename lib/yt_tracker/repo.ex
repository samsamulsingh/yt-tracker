defmodule YtTracker.Repo do
  use Ecto.Repo,
    otp_app: :yt_tracker,
    adapter: Ecto.Adapters.Postgres
end
