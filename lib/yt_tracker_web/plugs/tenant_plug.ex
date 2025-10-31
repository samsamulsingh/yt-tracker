defmodule YtTrackerWeb.Plugs.TenantPlug do
  @moduledoc """
  Resolves tenant from X-Tenant-Id header or defaults to "public".
  """

  import Plug.Conn
  alias YtTracker.Tenancy

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant_slug = get_req_header(conn, "x-tenant-id") |> List.first() || "public"

    case Tenancy.get_tenant_by_slug(tenant_slug) do
      nil ->
        conn
        |> put_status(:bad_request)
        |> Phoenix.Controller.json(%{
          error: %{
            type: "invalid_tenant",
            title: "Invalid Tenant",
            detail: "Tenant '#{tenant_slug}' not found"
          }
        })
        |> halt()

      tenant ->
        conn
        |> assign(:tenant, tenant)
        |> assign(:tenant_id, tenant.id)
    end
  end
end
