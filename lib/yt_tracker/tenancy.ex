defmodule YtTracker.Tenancy do
  @moduledoc """
  The Tenancy context for managing tenants.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Tenancy.Tenant

  @doc """
  Returns the list of tenants.
  """
  def list_tenants do
    Repo.all(Tenant)
  end

  @doc """
  Gets a single tenant.
  """
  def get_tenant!(id), do: Repo.get!(Tenant, id)

  @doc """
  Gets a tenant by slug.
  """
  def get_tenant_by_slug(slug) do
    Repo.get_by(Tenant, slug: slug)
  end

  @doc """
  Gets a tenant by slug, raising if not found.
  """
  def get_tenant_by_slug!(slug) do
    Repo.get_by!(Tenant, slug: slug)
  end

  @doc """
  Creates a tenant.
  """
  def create_tenant(attrs \\ %{}) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tenant.
  """
  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tenant.
  """
  def delete_tenant(%Tenant{} = tenant) do
    Repo.delete(tenant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tenant changes.
  """
  def change_tenant(%Tenant{} = tenant, attrs \\ %{}) do
    Tenant.changeset(tenant, attrs)
  end

  @doc """
  Gets or creates the default "public" tenant.
  """
  def get_or_create_public_tenant do
    case get_tenant_by_slug("public") do
      nil ->
        {:ok, tenant} = create_tenant(%{name: "Public", slug: "public", active: true})
        tenant

      tenant ->
        tenant
    end
  end
end
