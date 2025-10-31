defmodule YtTracker.TenancyTest do
  use YtTracker.DataCase

  alias YtTracker.Tenancy

  describe "tenants" do
    @valid_attrs %{name: "Test Tenant", slug: "test-tenant"}
    @invalid_attrs %{name: nil, slug: nil}

    test "list_tenants/0 returns all tenants" do
      {:ok, tenant} = Tenancy.create_tenant(@valid_attrs)
      assert tenant in Tenancy.list_tenants()
    end

    test "get_tenant!/1 returns the tenant with given id" do
      {:ok, tenant} = Tenancy.create_tenant(@valid_attrs)
      assert Tenancy.get_tenant!(tenant.id).id == tenant.id
    end

    test "get_tenant_by_slug/1 returns the tenant with given slug" do
      {:ok, tenant} = Tenancy.create_tenant(@valid_attrs)
      assert Tenancy.get_tenant_by_slug("test-tenant").id == tenant.id
    end

    test "create_tenant/1 with valid data creates a tenant" do
      assert {:ok, tenant} = Tenancy.create_tenant(@valid_attrs)
      assert tenant.name == "Test Tenant"
      assert tenant.slug == "test-tenant"
      assert tenant.active == true
    end

    test "create_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tenancy.create_tenant(@invalid_attrs)
    end

    test "create_tenant/1 with duplicate slug returns error" do
      {:ok, _tenant} = Tenancy.create_tenant(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Tenancy.create_tenant(@valid_attrs)
    end

    test "update_tenant/2 with valid data updates the tenant" do
      {:ok, tenant} = Tenancy.create_tenant(@valid_attrs)
      update_attrs = %{name: "Updated Name"}

      assert {:ok, updated} = Tenancy.update_tenant(tenant, update_attrs)
      assert updated.name == "Updated Name"
    end

    test "delete_tenant/1 deletes the tenant" do
      {:ok, tenant} = Tenancy.create_tenant(@valid_attrs)
      assert {:ok, _} = Tenancy.delete_tenant(tenant)
      assert_raise Ecto.NoResultsError, fn -> Tenancy.get_tenant!(tenant.id) end
    end

    test "get_or_create_public_tenant/0 creates public tenant if not exists" do
      tenant = Tenancy.get_or_create_public_tenant()
      assert tenant.slug == "public"
      assert tenant.name == "Public"
    end
  end
end
