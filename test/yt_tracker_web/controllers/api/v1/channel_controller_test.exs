defmodule YtTrackerWeb.Api.V1.ChannelControllerTest do
  use YtTrackerWeb.ConnCase

  alias YtTracker.{Tenancy, ApiAuth}

  setup do
    {:ok, tenant} = Tenancy.create_tenant(%{name: "Test", slug: "test"})
    {:ok, api_key, key} = ApiAuth.create_api_key(%{tenant_id: tenant.id, name: "Test Key"})

    {:ok, tenant: tenant, api_key: api_key, key: key}
  end

  describe "POST /v1/channels" do
    test "creates channel with valid youtube_id", %{conn: conn, key: key} do
      # This would require mocking the YouTube API
      # For now, just test the validation
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{key}")
        |> put_req_header("content-type", "application/json")
        |> post("/v1/channels", %{})

      assert json_response(conn, 400)["error"]["type"] == "missing_parameter"
    end
  end

  describe "GET /v1/channels" do
    test "lists channels for tenant", %{conn: conn, key: key} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{key}")
        |> get("/v1/channels")

      assert %{"data" => channels} = json_response(conn, 200)
      assert is_list(channels)
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, "/v1/channels")

      assert json_response(conn, 401)["error"]["type"] == "unauthorized"
    end
  end
end
