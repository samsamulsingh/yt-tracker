defmodule YtTrackerWeb.ChannelFormLive do
  use YtTrackerWeb, :live_view

  import Ecto.Query

  alias YtTracker.Channels

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-8 px-4">
      <div class="bg-white shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Add YouTube Channel
          </h3>
          <div class="mt-2 max-w-xl text-sm text-gray-500">
            <p>Enter a YouTube channel ID or handle to start tracking.</p>
            <p class="mt-1">Examples:</p>
            <ul class="list-disc ml-5 mt-1">
              <li><strong>Channel ID:</strong> UCX6OQ3DkcsbYNE6H8uQQuVA</li>
              <li><strong>Handle:</strong> @Shoagsikdar</li>
              <li><strong>Channel URL:</strong> https://www.youtube.com/channel/UCX6OQ3DkcsbYNE6H8uQQuVA</li>
              <li><strong>Handle URL:</strong> https://www.youtube.com/@Shoagsikdar</li>
            </ul>
          </div>
          <.form for={@form} id="channel_form" action="#" phx-submit="save" phx-change="validate">
            <.input
              field={@form[:channel_id]}
              type="text"
              label="YouTube Channel ID, Handle, or URL"
              placeholder="@Shoagsikdar or UCX6OQ3DkcsbYNE6H8uQQuVA"
              required
            />

            <button
              type="submit"
              phx-disable-with="Adding..."
              class="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Add Channel
            </button>
            <.link
              navigate={~p"/"}
              class="ml-3 inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Cancel
            </.link>
          </.form>
        </div>
      </div>

      <%= if @channels != [] do %>
        <div class="mt-8 bg-white shadow sm:rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
              Your Tracked Channels
            </h3>
            <ul role="list" class="divide-y divide-gray-200">
              <%= for channel <- @channels do %>
                <li class="py-4 flex items-center justify-between">
                  <div class="flex items-center">
                    <%= if channel.thumbnail_url do %>
                      <img class="h-10 w-10 rounded-full" src={channel.thumbnail_url} alt="" />
                    <% end %>
                    <div class="ml-3">
                      <p class="text-sm font-medium text-gray-900"><%= channel.title %></p>
                      <p class="text-sm text-gray-500"><%= channel.channel_id %></p>
                    </div>
                  </div>
                  <button
                    phx-click="delete"
                    phx-value-id={channel.id}
                    data-confirm="Are you sure you want to remove this channel?"
                    class="ml-4 flex-shrink-0 text-sm font-medium text-red-600 hover:text-red-500"
                  >
                    Remove
                  </button>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, session, socket) do
    current_user = get_current_user(session)

    if current_user do
      changeset = Channels.change_channel(%Channels.YoutubeChannel{})
      channels = list_user_channels(current_user)

      socket =
        socket
        |> assign(:current_user, current_user)
        |> assign(:channels, channels)
        |> assign(:page_title, "Add Channel")
        |> assign_form(changeset)

      {:ok, socket}
    else
      {:ok, push_navigate(socket, to: ~p"/login")}
    end
  end

  def handle_event("validate", %{"channel" => channel_params}, socket) do
    changeset =
      %{}
      |> Channels.change_channel(channel_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"channel" => channel_params}, socket) do
    channel_id = extract_channel_id(channel_params["channel_id"])

    # Validate channel ID or handle format
    cond do
      # Valid channel ID: starts with UC and is 24 characters
      String.starts_with?(channel_id, "UC") && String.length(channel_id) == 24 ->
        create_channel(channel_id, socket)
      
      # Valid handle: starts with @ or is alphanumeric
      String.starts_with?(channel_id, "@") || Regex.match?(~r/^[a-zA-Z0-9_-]+$/, channel_id) ->
        create_channel(channel_id, socket)
      
      # Invalid format
      true ->
        socket =
          socket
          |> put_flash(:error, "Invalid channel ID or handle. Please use a valid YouTube channel ID (UCxxxxxx) or handle (@username).")
        
        {:noreply, socket}
    end
  end

  defp create_channel(channel_id, socket) do
    attrs = %{
      channel_id: channel_id,
      tenant_id: socket.assigns.current_user.tenant_id,
      user_id: socket.assigns.current_user.id
    }

    case Channels.create_or_get_channel(attrs) do
      {:ok, _channel} ->
        channels = list_user_channels(socket.assigns.current_user)

        socket =
          socket
          |> put_flash(:info, "Channel added successfully!")
          |> assign(:channels, channels)
          |> assign_form(Channels.change_channel(%{}))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
      
      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to add channel: #{inspect(reason)}")
        
        {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    channel = Channels.get_channel!(socket.assigns.current_user.tenant_id, id)
    {:ok, _} = Channels.delete_channel(channel)

    channels = list_user_channels(socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, "Channel removed successfully")
     |> assign(:channels, channels)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "channel"))
  end

  defp get_current_user(session) do
    if user_token = session["user_token"] do
      YtTracker.Accounts.get_user_by_session_token(user_token)
    end
  end

  defp list_user_channels(user) do
    YtTracker.Repo.all(
      from c in YtTracker.Channels.YoutubeChannel,
        where: c.user_id == ^user.id,
        order_by: [desc: c.inserted_at]
    )
  end

  defp extract_channel_id(input) do
    cond do
      # Already a channel ID
      String.starts_with?(input, "UC") && String.length(input) == 24 ->
        input

      # URL with channel ID
      String.contains?(input, "/channel/") ->
        input
        |> String.split("/channel/")
        |> List.last()
        |> String.split("?")
        |> List.first()

      # Handle @username format
      String.contains?(input, "@") ->
        input
        |> String.split("@")
        |> List.last()
        |> String.split("/")
        |> List.first()

      # Default: return as-is
      true ->
        input
    end
  end
end
