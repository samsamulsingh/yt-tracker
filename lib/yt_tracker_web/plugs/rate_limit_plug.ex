defmodule YtTrackerWeb.Plugs.RateLimitPlug do
  @moduledoc """
  Rate limiting for API requests based on API key or IP address.
  Uses a simple in-memory counter with ETS (or could use Redis for distributed systems).
  """

  import Plug.Conn

  @table_name :rate_limit_counters

  def init(opts), do: opts

  def call(conn, _opts) do
    # Create ETS table if it doesn't exist
    ensure_table_exists()

    key = rate_limit_key(conn)
    {limit, window} = get_rate_limit_config(conn)

    case check_rate_limit(key, limit, window) do
      :ok ->
        conn

      {:error, :rate_limited, retry_after} ->
        conn
        |> put_status(:too_many_requests)
        |> put_resp_header("retry-after", to_string(retry_after))
        |> Phoenix.Controller.json(%{
          error: %{
            type: "rate_limit_exceeded",
            title: "Rate Limit Exceeded",
            detail: "Too many requests. Please try again in #{retry_after} seconds."
          }
        })
        |> halt()
    end
  end

  defp ensure_table_exists do
    unless :ets.whereis(@table_name) != :undefined do
      :ets.new(@table_name, [:named_table, :public, :set])
    end
  end

  defp rate_limit_key(conn) do
    # Use API key ID if available, otherwise use IP address
    case conn.assigns[:api_key] do
      nil ->
        {:ip, get_ip_address(conn)}

      api_key ->
        {:api_key, api_key.id}
    end
  end

  defp get_ip_address(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      _ -> to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end

  defp get_rate_limit_config(conn) do
    # Check if API key has custom rate limit
    case conn.assigns[:api_key] do
      %{rate_limit: limit, rate_window_seconds: window}
      when not is_nil(limit) and not is_nil(window) ->
        {limit, window}

      _ ->
        # Use default from config
        config = Application.get_env(:yt_tracker, :rate_limit, [])
        {config[:default_limit] || 100, config[:default_window_seconds] || 60}
    end
  end

  defp check_rate_limit(key, limit, window_seconds) do
    now = System.system_time(:second)
    window_start = now - window_seconds

    # Get current count for this window
    count =
      case :ets.lookup(@table_name, key) do
        [{^key, count, timestamp}] when timestamp > window_start ->
          count

        _ ->
          0
      end

    if count >= limit do
      # Calculate retry_after
      case :ets.lookup(@table_name, key) do
        [{^key, _count, timestamp}] ->
          retry_after = timestamp + window_seconds - now
          {:error, :rate_limited, max(retry_after, 1)}

        _ ->
          {:error, :rate_limited, window_seconds}
      end
    else
      # Increment counter
      :ets.insert(@table_name, {key, count + 1, now})
      :ok
    end
  end
end
