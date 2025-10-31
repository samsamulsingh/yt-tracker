import Config

# Runtime configuration for production and other environments
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :yt_tracker, YtTracker.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :yt_tracker, YtTrackerWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Oban configuration for production
  config :yt_tracker, Oban,
    repo: YtTracker.Repo,
    plugins: [
      {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 30},
      {Oban.Plugins.Cron,
       crontab: [
         {"*/15 * * * *", YtTracker.Workers.PollRss},
         {"*/5 * * * *", YtTracker.Workers.MonitorChannels}
       ]}
    ],
    queues: [
      default: 10,
      backfill: 5,
      enrich: 10,
      rss: 5,
      webhooks: 20,
      monitoring: 10
    ]
end

# Feature flags
config :yt_tracker, :features,
  websub_enabled: System.get_env("WEBSUB_ENABLED") == "true",
  public_api_enabled: System.get_env("PUBLIC_API_ENABLED", "true") == "true"

# YouTube API configuration
config :yt_tracker, :youtube,
  api_key: System.get_env("YOUTUBE_API_KEY")

# CORS allowed origins
config :yt_tracker, :cors,
  allowed_origins:
    (System.get_env("ALLOW_ORIGINS") || "http://localhost:3000")
    |> String.split(",")
    |> Enum.map(&String.trim/1)

# Rate limiting
config :yt_tracker, :rate_limit,
  default_limit: String.to_integer(System.get_env("RATE_LIMIT", "100")),
  default_window_seconds: String.to_integer(System.get_env("RATE_LIMIT_WINDOW", "60"))
