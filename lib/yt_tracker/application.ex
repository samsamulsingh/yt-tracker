defmodule YtTracker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      YtTrackerWeb.Telemetry,
      YtTracker.Repo,
      {DNSCluster, query: Application.get_env(:yt_tracker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: YtTracker.PubSub},
      {Finch, name: YtTracker.Finch},
      {Oban, Application.fetch_env!(:yt_tracker, Oban)},
      YtTrackerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: YtTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    YtTrackerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
