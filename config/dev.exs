import Config

# Configure your database
config :yt_tracker, YtTracker.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "yt_tracker_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :yt_tracker, YtTrackerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_at_least_64_bytes_long_for_security_purposes_12345",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:yt_tracker, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:yt_tracker, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/yt_tracker_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Enable dev routes for dashboard and mailbox
config :yt_tracker, dev_routes: true

# Oban configuration for development
config :yt_tracker, Oban,
  repo: YtTracker.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       # Poll RSS feeds every 15 minutes
       {"*/15 * * * *", YtTracker.Workers.PollRss},
       # Check channel monitors every 5 minutes
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

# YouTube API Configuration
# Get your API key from: https://console.cloud.google.com/apis/credentials
config :yt_tracker, :youtube_api_key, System.get_env("YOUTUBE_API_KEY") || "YOUR_API_KEY_HERE"
