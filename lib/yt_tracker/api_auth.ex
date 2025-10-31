defmodule YtTracker.ApiAuth do
  @moduledoc """
  The ApiAuth context for managing API keys.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.ApiAuth.ApiKey

  @doc """
  Lists all API keys for a tenant.
  """
  def list_api_keys(tenant_id) do
    ApiKey
    |> where(tenant_id: ^tenant_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single API key.
  """
  def get_api_key!(tenant_id, id) do
    ApiKey
    |> where(tenant_id: ^tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates an API key and returns the full key (only shown once).
  """
  def create_api_key(attrs \\ %{}) do
    {key, prefix, hash} = ApiKey.generate_key()

    attrs =
      attrs
      |> Map.put(:key_hash, hash)
      |> Map.put(:key_prefix, prefix)

    case %ApiKey{}
         |> ApiKey.changeset(attrs)
         |> Repo.insert() do
      {:ok, api_key} ->
        {:ok, api_key, key}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes an API key.
  """
  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  @doc """
  Authenticates a request with an API key.
  Returns {:ok, api_key} or {:error, reason}
  """
  def authenticate(key) when is_binary(key) do
    hash = :crypto.hash(:sha256, key) |> Base.encode16(case: :lower)

    case Repo.get_by(ApiKey, key_hash: hash) do
      nil ->
        {:error, :invalid_key}

      api_key ->
        if api_key.active and not expired?(api_key) do
          update_last_used(api_key)
          {:ok, api_key |> Repo.preload(:tenant)}
        else
          {:error, :inactive_or_expired}
        end
    end
  end

  defp expired?(%ApiKey{expires_at: nil}), do: false

  defp expired?(%ApiKey{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  defp update_last_used(api_key) do
    api_key
    |> ApiKey.changeset(%{last_used_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
