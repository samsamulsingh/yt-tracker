defmodule YtTracker.Workers.MonitorChannels do
  @moduledoc """
  Oban worker that checks all active channel monitors and triggers polls.
  """
  use Oban.Worker,
    queue: :monitoring,
    max_attempts: 3

  alias YtTracker.Monitoring

  @impl Oban.Worker
  def perform(_job) do
    monitors = Monitoring.list_monitors_due_for_check()

    Enum.each(monitors, fn monitor ->
      case Monitoring.process_monitor_check(monitor) do
        {:ok, _} -> :ok
        {:error, reason} -> IO.puts("Monitor check failed: #{inspect(reason)}")
      end
    end)

    :ok
  end
end
