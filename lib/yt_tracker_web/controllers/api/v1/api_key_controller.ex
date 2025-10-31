defmodule YtTrackerWeb.Api.V1.ApiKeyController do
  use YtTrackerWeb, :controller
  import YtTrackerWeb.ResponseHelpers

  alias YtTracker.ApiAuth

  def create(conn, %{"name" => name} = params) do
    tenant_id = conn.assigns.tenant_id

    attrs = %{
      tenant_id: tenant_id,
      name: name,
      rate_limit: params["rate_limit"],
      rate_window_seconds: params["rate_window_seconds"],
      scopes: params["scopes"] || [],
      expires_at: parse_expires_at(params["expires_at"])
    }

    case ApiAuth.create_api_key(attrs) do
      {:ok, api_key, key} ->
        render_success(
          conn,
          %{
            id: api_key.id,
            name: api_key.name,
            key: key,
            key_prefix: api_key.key_prefix,
            rate_limit: api_key.rate_limit,
            rate_window_seconds: api_key.rate_window_seconds,
            scopes: api_key.scopes,
            expires_at: api_key.expires_at,
            created_at: api_key.inserted_at,
            warning: "Save this key securely. It will not be shown again."
          },
          status: :created
        )

      {:error, changeset} ->
        render_changeset_error(conn, changeset)
    end
  end

  def create(conn, _params) do
    render_error(conn, "missing_parameter", "Missing Parameter", "name is required")
  end

  def index(conn, _params) do
    tenant_id = conn.assigns.tenant_id
    api_keys = ApiAuth.list_api_keys(tenant_id)

    render_success(conn, Enum.map(api_keys, &serialize_api_key/1))
  end

  def delete(conn, %{"id" => id}) do
    tenant_id = conn.assigns.tenant_id
    api_key = ApiAuth.get_api_key!(tenant_id, id)

    case ApiAuth.delete_api_key(api_key) do
      {:ok, _} ->
        render_success(conn, %{message: "API key deleted"})

      {:error, _} ->
        render_error(conn, "delete_error", "Delete Error", "Failed to delete API key")
    end
  end

  defp parse_expires_at(nil), do: nil

  defp parse_expires_at(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp serialize_api_key(api_key) do
    %{
      id: api_key.id,
      name: api_key.name,
      key_prefix: api_key.key_prefix,
      active: api_key.active,
      rate_limit: api_key.rate_limit,
      rate_window_seconds: api_key.rate_window_seconds,
      scopes: api_key.scopes,
      last_used_at: api_key.last_used_at,
      expires_at: api_key.expires_at,
      created_at: api_key.inserted_at
    }
  end
end
