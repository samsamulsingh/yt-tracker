defmodule YtTracker.ApiAuthTest do
  use YtTracker.DataCase

  alias YtTracker.{Tenancy, ApiAuth}

  setup do
    {:ok, tenant} = Tenancy.create_tenant(%{name: "Test", slug: "test"})
    {:ok, tenant: tenant}
  end

  describe "api_keys" do
    test "create_api_key/1 generates a valid key", %{tenant: tenant} do
      attrs = %{tenant_id: tenant.id, name: "Test Key"}

      assert {:ok, api_key, key} = ApiAuth.create_api_key(attrs)
      assert String.starts_with?(key, "yttr_")
      assert api_key.key_prefix == String.slice(key, 0, 12)
      assert api_key.active == true
    end

    test "authenticate/1 with valid key returns api_key", %{tenant: tenant} do
      attrs = %{tenant_id: tenant.id, name: "Test Key"}
      {:ok, _api_key, key} = ApiAuth.create_api_key(attrs)

      assert {:ok, authenticated_key} = ApiAuth.authenticate(key)
      assert authenticated_key.tenant_id == tenant.id
    end

    test "authenticate/1 with invalid key returns error" do
      assert {:error, :invalid_key} = ApiAuth.authenticate("invalid_key")
    end

    test "authenticate/1 with inactive key returns error", %{tenant: tenant} do
      attrs = %{tenant_id: tenant.id, name: "Test Key"}
      {:ok, api_key, key} = ApiAuth.create_api_key(attrs)

      # Deactivate the key
      ApiAuth.delete_api_key(api_key)

      assert {:error, :invalid_key} = ApiAuth.authenticate(key)
    end

    test "list_api_keys/1 returns all keys for tenant", %{tenant: tenant} do
      {:ok, _api_key1, _} = ApiAuth.create_api_key(%{tenant_id: tenant.id, name: "Key 1"})
      {:ok, _api_key2, _} = ApiAuth.create_api_key(%{tenant_id: tenant.id, name: "Key 2"})

      keys = ApiAuth.list_api_keys(tenant.id)
      assert length(keys) == 2
    end
  end
end
