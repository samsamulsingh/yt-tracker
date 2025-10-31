defmodule YtTrackerWeb.Api.V1.WebhookController do
  use YtTrackerWeb, :controller
  import YtTrackerWeb.ResponseHelpers

  alias YtTracker.Webhooks

  def create_endpoint(conn, %{"url" => url} = params) do
    tenant_id = conn.assigns.tenant_id

    attrs = %{
      tenant_id: tenant_id,
      url: url,
      events: params["events"] || ["*"],
      description: params["description"]
    }

    case Webhooks.create_endpoint(attrs) do
      {:ok, endpoint} ->
        render_success(conn, serialize_endpoint(endpoint), status: :created)

      {:error, changeset} ->
        render_changeset_error(conn, changeset)
    end
  end

  def create_endpoint(conn, _params) do
    render_error(conn, "missing_parameter", "Missing Parameter", "url is required")
  end

  def list_endpoints(conn, _params) do
    tenant_id = conn.assigns.tenant_id
    endpoints = Webhooks.list_endpoints(tenant_id)

    render_success(conn, Enum.map(endpoints, &serialize_endpoint/1))
  end

  def show_endpoint(conn, %{"id" => id}) do
    tenant_id = conn.assigns.tenant_id
    endpoint = Webhooks.get_endpoint!(tenant_id, id)

    render_success(conn, serialize_endpoint(endpoint))
  end

  def delete_endpoint(conn, %{"id" => id}) do
    tenant_id = conn.assigns.tenant_id
    endpoint = Webhooks.get_endpoint!(tenant_id, id)

    case Webhooks.delete_endpoint(endpoint) do
      {:ok, _} ->
        render_success(conn, %{message: "Webhook endpoint deleted"})

      {:error, _} ->
        render_error(conn, "delete_error", "Delete Error", "Failed to delete webhook endpoint")
    end
  end

  def list_deliveries(conn, params) do
    tenant_id = conn.assigns.tenant_id
    opts = if params["endpoint_id"], do: [endpoint_id: params["endpoint_id"]], else: []

    deliveries = Webhooks.list_deliveries(tenant_id, opts)

    render_success(conn, Enum.map(deliveries, &serialize_delivery/1))
  end

  defp serialize_endpoint(endpoint) do
    %{
      id: endpoint.id,
      url: endpoint.url,
      secret: endpoint.secret,
      events: endpoint.events,
      description: endpoint.description,
      active: endpoint.active,
      created_at: endpoint.inserted_at,
      updated_at: endpoint.updated_at
    }
  end

  defp serialize_delivery(delivery) do
    %{
      id: delivery.id,
      endpoint_id: delivery.endpoint_id,
      event_type: delivery.event_type,
      status: delivery.status,
      attempt_count: delivery.attempt_count,
      response_status: delivery.response_status,
      sent_at: delivery.sent_at,
      created_at: delivery.inserted_at
    }
  end
end
