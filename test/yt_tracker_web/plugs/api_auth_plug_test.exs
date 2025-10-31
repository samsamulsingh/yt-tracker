defmodule YtTrackerWeb.Plugs.ApiAuthPlugTest do
  use YtTrackerWeb.ConnCase

  alias YtTracker.{Tenancy, ApiAuth}
  alias YtTrackerWeb.Plugs.ApiAuthPlug

  setup do
    {:ok, tenant} = Tenancy.create_tenant(%{name: "Test", slug: "test"})
    {:ok, _api_key, key} = ApiAuth.create_api_key(%{tenant_id: tenant.id, name: "Test Key"})

    {:ok, tenant: tenant, key: key}
  end

  describe "call/2" do
    test "authenticates with valid Bearer token", %{conn: conn, key: key, tenant: tenant} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{key}")
        |> ApiAuthPlug.call([])

      refute conn.halted
      assert conn.assigns.tenant_id == tenant.id
    end

    test "rejects request without authorization header", %{conn: conn} do
      conn = ApiAuthPlug.call(conn, [])

      assert conn.halted
      assert conn.status == 401
    end

    test "rejects request with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid_token")
        |> ApiAuthPlug.call([])

      assert conn.halted
      assert conn.status == 401
    end

    test "rejects request with malformed authorization header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "InvalidFormat")
        |> ApiAuthPlug.call([])

      assert conn.halted
      assert conn.status == 401
    end
  end
end
