# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias YtTracker.{Tenancy, ApiAuth}

# Create default "public" tenant
{:ok, public_tenant} =
  case Tenancy.get_tenant_by_slug("public") do
    nil ->
      Tenancy.create_tenant(%{
        name: "Public",
        slug: "public",
        active: true
      })

    tenant ->
      {:ok, tenant}
  end

IO.puts("✓ Created public tenant: #{public_tenant.id}")

# Create a default API key for development
{:ok, api_key, key} =
  ApiAuth.create_api_key(%{
    tenant_id: public_tenant.id,
    name: "Development Key",
    rate_limit: 1000,
    rate_window_seconds: 60,
    scopes: ["*"]
  })

IO.puts("✓ Created development API key")
IO.puts("  Key: #{key}")
IO.puts("  Prefix: #{api_key.key_prefix}")
IO.puts("")
IO.puts("Save this API key! It will not be shown again.")
IO.puts("Use it with: Authorization: Bearer #{key}")
