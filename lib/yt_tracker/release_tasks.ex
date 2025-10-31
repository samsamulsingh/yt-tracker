defmodule YtTracker.ReleaseTasks do
  @moduledoc """
  Helper tasks to be run inside a release. Currently provides a `migrate/0`
  function to run Ecto migrations in production without Mix.
  """

  @app :yt_tracker

  def migrate do
    IO.puts("Starting release tasks for #{@app}...")

    # Ensure logger is started (helpful for seeing output in remote shells)
    {:ok, _} = Application.ensure_all_started(:logger)

    # Load and start the application
    Application.load(@app)
    {:ok, _} = Application.ensure_all_started(@app)

    repos()
    |> Enum.each(&run_migrations_for_repo/1)

    IO.puts("Migrations finished. Stopping system.")

    # Stop the node so the eval session exits cleanly
    :init.stop()
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp run_migrations_for_repo(repo) do
    IO.puts("Running migrations for repo: #{inspect(repo)}")
    Ecto.Migrator.run(repo, :up, all: true)
  end
end
