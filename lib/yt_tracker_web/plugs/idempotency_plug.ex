defmodule YtTrackerWeb.Plugs.IdempotencyPlug do
  @moduledoc """
  Handles idempotency for POST/PUT/PATCH requests using Idempotency-Key header.
  """

  import Plug.Conn
  alias YtTracker.{Repo, IdempotencyKey}

  # Only apply to mutating methods
  @mutating_methods ~w(POST PUT PATCH DELETE)

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.method in @mutating_methods do
      handle_idempotency(conn)
    else
      conn
    end
  end

  defp handle_idempotency(conn) do
    case get_req_header(conn, "idempotency-key") do
      [] ->
        conn

      [key] ->
        check_idempotency(conn, key)
    end
  end

  defp check_idempotency(conn, key) do
    tenant_id = conn.assigns[:tenant_id]

    if tenant_id do
      case Repo.get_by(IdempotencyKey,
             tenant_id: tenant_id,
             idempotency_key: key
           ) do
        nil ->
          # First time seeing this key, store request info
          register_before_send(conn, fn conn ->
            store_idempotency_result(conn, key, tenant_id)
          end)

        existing ->
          # Return cached response
          return_cached_response(conn, existing)
      end
    else
      conn
    end
  end

  defp store_idempotency_result(conn, key, tenant_id) do
    # Only store successful responses
    if conn.status in 200..299 do
      {:ok, body, conn} = read_body(conn)

      %IdempotencyKey{}
      |> IdempotencyKey.changeset(%{
        tenant_id: tenant_id,
        idempotency_key: key,
        request_path: conn.request_path,
        request_method: conn.method,
        request_params: conn.params,
        response_status: conn.status,
        response_body: body,
        created_at: DateTime.utc_now()
      })
      |> Repo.insert()

      conn
    else
      conn
    end
  end

  defp return_cached_response(conn, cached) do
    conn
    |> put_status(cached.response_status || 200)
    |> put_resp_content_type("application/json")
    |> send_resp(cached.response_status || 200, cached.response_body || "{}")
    |> halt()
  end
end
