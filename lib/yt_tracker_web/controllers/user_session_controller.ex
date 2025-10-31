defmodule YtTrackerWeb.UserSessionController do
  use YtTrackerWeb, :controller

  alias YtTracker.Accounts

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> put_session(:user_token, Accounts.generate_user_session_token(user))
      |> put_session(:live_socket_id, "users_sessions:#{user.id}")
      |> redirect(to: "/")
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> redirect(to: "/login")
    end
  end

  # Fallback for cached registration form submissions
  def register_redirect(conn, params) do
    # Extract and normalize user params to string keys
    user_params = case params do
      %{"user" => user_data} when is_map(user_data) -> 
        # Convert atom keys to strings if present
        for {key, value} <- user_data, into: %{} do
          {to_string(key), value}
        end
      other when is_map(other) -> 
        for {key, value} <- other, into: %{} do
          {to_string(key), value}
        end
      _ -> 
        %{}
    end
    
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: "/login?email=#{URI.encode(user.email)}")

      {:error, changeset} ->
        # Extract error messages
        error_message = 
          case changeset.errors do
            [{:email, {msg, _}} | _] -> "Email #{msg}"
            [{:password, {msg, _}} | _] -> "Password #{msg}"
            _ -> "There was a problem creating your account. Please try again."
          end
        
        conn
        |> put_flash(:error, error_message)
        |> redirect(to: "/register")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> delete_session(:user_token)
    |> delete_session(:live_socket_id)
    |> redirect(to: "/login")
  end
end
