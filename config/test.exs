import Config

# Configure your database
config :yt_tracker, YtTracker.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "yt_tracker_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test
config :yt_tracker, YtTrackerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_64_bytes_long_for_security_purposes_12345",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Oban configuration for testing - disable all plugins
config :yt_tracker, Oban,
  repo: YtTracker.Repo,
  testing: :manual,
  queues: false,
  plugins: false
