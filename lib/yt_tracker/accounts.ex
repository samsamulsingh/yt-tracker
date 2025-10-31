defmodule YtTracker.Accounts do
  @moduledoc """
  The Accounts context for user management and authentication.
  """

  import Ecto.Query, warn: false
  alias YtTracker.Repo
  alias YtTracker.Accounts.{User, UserToken}

  ## User Registration

  @doc """
  Registers a user.
  """
  def register_user(attrs) do
    # Get or create default tenant if not provided
    tenant_id =
      attrs[:tenant_id] ||
        attrs["tenant_id"] ||
        get_or_create_default_tenant()

    # Ensure we use string keys consistently
    attrs = Map.put(attrs, "tenant_id", tenant_id)

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  defp get_or_create_default_tenant do
    case Repo.get_by(YtTracker.Tenancy.Tenant, slug: "default") do
      nil ->
        {:ok, tenant} =
          %YtTracker.Tenancy.Tenant{}
          |> YtTracker.Tenancy.Tenant.changeset(%{
            name: "Default Tenant",
            slug: "default",
            active: true
          })
          |> Repo.insert()

        tenant.id

      tenant ->
        tenant.id
    end
  end

  ## User Lookup

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  @doc """
  Delivers the confirmation email instructions.
  For now, just returns ok since we don't have email configured.
  """
  def deliver_user_confirmation_instructions(%User{} = _user, _confirmation_url_fun) do
    {:ok, %{to: nil, body: nil}}
  end

  ## Session Management

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Deletes all tokens for the given user.
  """
  def delete_all_user_tokens(user) do
    Repo.delete_all(UserToken.by_user_and_contexts_query(user, :all))
  end
end
