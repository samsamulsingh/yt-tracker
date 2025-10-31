defmodule YtTrackerWeb.ChannelWebController do
  use YtTrackerWeb, :controller

  alias YtTracker.Channels
  alias YtTracker.Accounts

  # Skip CSRF check for this fallback route since it comes from LiveView
  plug :put_secure_browser_headers when action in [:create]

  # Fallback for cached channel form submissions
  def create(conn, params) do
    user_token = get_session(conn, :user_token)
    user = user_token && Accounts.get_user_by_session_token(user_token)

    if user do
      channel_id = params["channel_id"] || get_in(params, ["channel", "channel_id"]) || ""
      
      # Extract actual channel ID from URL if needed
      extracted_id = extract_channel_id(channel_id)
      
      case Channels.create_or_get_channel(%{
        tenant_id: user.tenant_id,
        channel_id: extracted_id,
        user_id: user.id
      }) do
        {:ok, _channel} ->
          conn
          |> put_flash(:info, "Channel added successfully!")
          |> redirect(to: "/")

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Could not add channel. Please check the ID and try again.")
          |> redirect(to: "/channels/new")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in.")
      |> redirect(to: "/login")
    end
  end

  defp extract_channel_id(input) do
    cond do
      String.starts_with?(input, "UC") and String.length(input) == 24 ->
        input

      String.contains?(input, "youtube.com") or String.contains?(input, "youtu.be") ->
        case Regex.run(~r/(?:channel\/|@)([\w-]+)/, input) do
          [_, id] -> id
          _ -> input
        end

      true ->
        input
    end
  end
end
