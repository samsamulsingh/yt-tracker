import Config

# General application configuration
config :yt_tracker,
  ecto_repos: [YtTracker.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :yt_tracker, YtTrackerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: YtTrackerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: YtTracker.PubSub,
  live_view: [signing_salt: "yt_tracker"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :tenant_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild
config :esbuild,
  version: "0.19.5",
  yt_tracker: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.3.6",
  yt_tracker: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure Finch
config :yt_tracker, YtTracker.Finch,
  pools: %{
    default: [size: 32, count: 8]
  }

# Import environment specific config
import_config "#{config_env()}.exs"
