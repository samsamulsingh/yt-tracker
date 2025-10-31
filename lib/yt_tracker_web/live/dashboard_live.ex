defmodule YtTrackerWeb.DashboardLive do
  @moduledoc """
  LiveView dashboard for monitoring YouTube channels.
  """
  use YtTrackerWeb, :live_view

  import Ecto.Query

  alias YtTracker.{Channels, Videos, Collections, Monitoring}

  @impl true
  def mount(_params, session, socket) do
    current_user = get_current_user(session)

    if current_user do
      if connected?(socket) do
        # Subscribe to updates
        Phoenix.PubSub.subscribe(YtTracker.PubSub, "channels:updates")
        Phoenix.PubSub.subscribe(YtTracker.PubSub, "videos:updates")
      end

      socket =
        socket
        |> assign(:current_user, current_user)
        |> assign(:tenant_id, current_user.tenant_id)
        |> assign(:page_title, "Dashboard")
        |> load_dashboard_data()

      {:ok, socket}
    else
      {:ok, push_navigate(socket, to: ~p"/login")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Dashboard")
  end

  @impl true
  def handle_event("enable_monitoring", %{"channel_id" => channel_id}, socket) do
    case Monitoring.enable_monitoring(channel_id, frequency_minutes: 15) do
      {:ok, _monitor} ->
        socket =
          socket
          |> put_flash(:info, "Monitoring enabled")
          |> load_dashboard_data()

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to enable monitoring")}
    end
  end

  def handle_event("disable_monitoring", %{"channel_id" => channel_id}, socket) do
    case Monitoring.disable_monitoring(channel_id) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Monitoring disabled")
          |> load_dashboard_data()

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to disable monitoring")}
    end
  end

  @impl true
  def handle_info({:channel_updated, _channel}, socket) do
    {:noreply, load_dashboard_data(socket)}
  end

  def handle_info({:video_created, _video}, socket) do
    {:noreply, load_dashboard_data(socket)}
  end

  defp load_dashboard_data(socket) do
    user = socket.assigns.current_user
    tenant_id = user.tenant_id

    # Get only channels belonging to this user
    channels =
      YtTracker.Repo.all(
        from c in YtTracker.Channels.YoutubeChannel,
          where: c.user_id == ^user.id,
          order_by: [desc: c.inserted_at]
      )

    recent_videos = Videos.list_recent_videos(tenant_id, limit: 20)
    collections = Collections.list_collections(tenant_id)

    # Get monitoring status for each channel
    channels_with_monitoring =
      Enum.map(channels, fn channel ->
        monitor = YtTracker.Repo.get_by(YtTracker.Monitoring.ChannelMonitor, channel_id: channel.id)
        # Convert struct to map and add monitor field
        channel
        |> Map.from_struct()
        |> Map.put(:monitor, monitor)
      end)

    socket
    |> assign(:channels, channels_with_monitoring)
    |> assign(:recent_videos, recent_videos)
    |> assign(:collections, collections)
    |> assign(:stats, calculate_stats(channels_with_monitoring, recent_videos))
  end

  defp calculate_stats(channels, videos) do
    %{
      total_channels: length(channels),
      total_videos: length(videos),
      monitored_channels: Enum.count(channels, fn ch -> ch[:monitor] && ch[:monitor].enabled end)
    }
  end

  defp get_current_user(session) do
    if user_token = session["user_token"] do
      YtTracker.Accounts.get_user_by_session_token(user_token)
    end
  end

  defp get_or_create_default_tenant do
    # Try to get existing default tenant
    case YtTracker.Repo.get_by(YtTracker.Tenancy.Tenant, slug: "default") do
      nil ->
        # Create default tenant if it doesn't exist
        {:ok, tenant} =
          %YtTracker.Tenancy.Tenant{}
          |> YtTracker.Tenancy.Tenant.changeset(%{
            name: "Default Tenant",
            slug: "default",
            active: true
          })
          |> YtTracker.Repo.insert()

        tenant.id

      tenant ->
        tenant.id
    end
  end

  defp format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_number(_), do: "0"
end
