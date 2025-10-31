defmodule YtTracker.Settings do
  @moduledoc """
  The Settings context for managing application settings.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Settings.Setting

  @doc """
  Gets a setting by key for a tenant.
  """
  def get_setting(tenant_id, key) do
    Setting
    |> where(tenant_id: ^tenant_id, key: ^key)
    |> Repo.one()
  end

  @doc """
  Gets a setting value by key for a tenant.
  Returns the value or nil if not found.
  """
  def get_value(tenant_id, key) do
    case get_setting(tenant_id, key) do
      nil -> nil
      setting -> setting.value
    end
  end

  @doc """
  Sets a setting value for a tenant.
  Creates or updates the setting.
  """
  def set_setting(tenant_id, key, value, opts \\ []) do
    description = Keyword.get(opts, :description)
    
    case get_setting(tenant_id, key) do
      nil ->
        %Setting{}
        |> Setting.changeset(%{
          tenant_id: tenant_id,
          key: key,
          value: value,
          description: description
        })
        |> Repo.insert()

      setting ->
        setting
        |> Setting.changeset(%{value: value})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a setting.
  """
  def delete_setting(tenant_id, key) do
    case get_setting(tenant_id, key) do
      nil -> {:error, :not_found}
      setting -> Repo.delete(setting)
    end
  end

  @doc """
  Lists all settings for a tenant.
  """
  def list_settings(tenant_id) do
    Setting
    |> where(tenant_id: ^tenant_id)
    |> order_by(:key)
    |> Repo.all()
  end
end
