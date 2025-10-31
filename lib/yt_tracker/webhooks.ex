defmodule YtTracker.Webhooks do
  @moduledoc """
  The Webhooks context for managing webhook endpoints and deliveries.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Webhooks.{Endpoint, Delivery}
  alias YtTracker.Workers

  require Logger

  # Endpoint management

  @doc """
  Lists all webhook endpoints for a tenant.
  """
  def list_endpoints(tenant_id) do
    Endpoint
    |> where(tenant_id: ^tenant_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single endpoint.
  """
  def get_endpoint!(tenant_id, id) do
    Endpoint
    |> where(tenant_id: ^tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a webhook endpoint.
  """
  def create_endpoint(attrs \\ %{}) do
    attrs = Map.put_new(attrs, :secret, Endpoint.generate_secret())

    %Endpoint{}
    |> Endpoint.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a webhook endpoint.
  """
  def update_endpoint(%Endpoint{} = endpoint, attrs) do
    endpoint
    |> Endpoint.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a webhook endpoint.
  """
  def delete_endpoint(%Endpoint{} = endpoint) do
    Repo.delete(endpoint)
  end

  # Delivery management

  @doc """
  Lists deliveries for a tenant or endpoint.
  """
  def list_deliveries(tenant_id, opts \\ []) do
    query =
      Delivery
      |> where(tenant_id: ^tenant_id)

    query =
      case Keyword.get(opts, :endpoint_id) do
        nil -> query
        endpoint_id -> where(query, endpoint_id: ^endpoint_id)
      end

    query
    |> order_by(desc: :inserted_at)
    |> limit(100)
    |> Repo.all()
  end

  @doc """
  Gets a single delivery.
  """
  def get_delivery!(tenant_id, id) do
    Delivery
    |> where(tenant_id: ^tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Fires a webhook event to all matching endpoints.
  """
  def fire_event(tenant_id, event_type, payload) do
    endpoints = get_matching_endpoints(tenant_id, event_type)

    Logger.debug("Firing #{event_type} event to #{length(endpoints)} endpoints")

    Enum.each(endpoints, fn endpoint ->
      create_and_schedule_delivery(endpoint, event_type, payload)
    end)

    {:ok, length(endpoints)}
  end

  defp get_matching_endpoints(tenant_id, event_type) do
    Endpoint
    |> where(tenant_id: ^tenant_id, active: true)
    |> Repo.all()
    |> Enum.filter(fn endpoint ->
      "*" in endpoint.events or event_type in endpoint.events
    end)
  end

  defp create_and_schedule_delivery(endpoint, event_type, payload) do
    now = DateTime.utc_now()

    {:ok, delivery} =
      %Delivery{}
      |> Delivery.changeset(%{
        tenant_id: endpoint.tenant_id,
        endpoint_id: endpoint.id,
        event_type: event_type,
        payload: payload,
        status: "pending",
        next_attempt_at: now
      })
      |> Repo.insert()

    # Schedule delivery job
    %{delivery_id: delivery.id}
    |> Workers.WebhookDelivery.new(queue: :webhooks)
    |> Oban.insert()
  end
end
