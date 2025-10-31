defmodule YtTrackerWeb.Router do
  use YtTrackerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YtTrackerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :browser_no_csrf do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YtTrackerWeb.Layouts, :root}
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :require_auth do
    plug :require_authenticated_user
  end

  defp fetch_current_user(conn, _opts) do
    user_token = get_session(conn, :user_token)
    user = user_token && YtTracker.Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You must log in to access this page.")
      |> Phoenix.Controller.redirect(to: "/login")
      |> halt()
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug YtTrackerWeb.Plugs.ApiAuthPlug
    plug YtTrackerWeb.Plugs.RateLimitPlug
    plug YtTrackerWeb.Plugs.IdempotencyPlug
    plug CORSPlug, origin: Application.get_env(:yt_tracker, :cors, [])[:allowed_origins] || ["*"]
  end

  # LiveView routes
  scope "/", YtTrackerWeb do
    pipe_through :browser

    live "/login", UserLoginLive, :index
    post "/login", UserSessionController, :create
    live "/register", UserRegistrationLive, :index
    delete "/logout", UserSessionController, :delete
  end

  scope "/", YtTrackerWeb do
    pipe_through [:browser, :require_auth]

    live "/", DashboardLive, :index
    live "/channels/new", ChannelFormLive, :new
    live "/settings", SettingsLive, :index
    live "/channels/:youtube_id", ChannelDetailLive, :show
  end

  # Fallback routes for cached forms (no CSRF check)
  scope "/", YtTrackerWeb do
    pipe_through [:browser_no_csrf, :require_auth]

    post "/channels/new", ChannelWebController, :create
    post "/register", UserSessionController, :register_redirect
  end

  scope "/api/v1", YtTrackerWeb.Api.V1 do
    pipe_through :api

    # Status endpoint
    get "/status", StatusController, :show

    # Channels
    post "/channels", ChannelController, :create
    get "/channels", ChannelController, :index
    get "/channels/:id", ChannelController, :show
    post "/channels/:id/backfill", ChannelController, :backfill
    post "/channels/:id/poll", ChannelController, :poll
    get "/channels/:id/videos", ChannelController, :videos

    # Videos
    post "/videos/refresh", VideoController, :refresh

    # API Keys
    post "/api_keys", ApiKeyController, :create
    get "/api_keys", ApiKeyController, :index
    delete "/api_keys/:id", ApiKeyController, :delete

    # Webhooks
    post "/webhooks/endpoints", WebhookController, :create_endpoint
    get "/webhooks/endpoints", WebhookController, :list_endpoints
    get "/webhooks/endpoints/:id", WebhookController, :show_endpoint
    delete "/webhooks/endpoints/:id", WebhookController, :delete_endpoint
    get "/webhooks/deliveries", WebhookController, :list_deliveries
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:yt_tracker, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: YtTrackerWeb.Telemetry
    end
  end
end
