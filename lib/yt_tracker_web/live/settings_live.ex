defmodule YtTrackerWeb.SettingsLive do
  use YtTrackerWeb, :live_view
  alias YtTracker.{ApiAuth, Settings}

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
      <!-- LiveView Connection Debug -->
      <div class="mb-4 p-4 bg-red-100 border border-red-400 rounded">
        <p class="font-bold text-red-800">DEBUG: LiveView Connection Status</p>
        <p class="text-sm text-red-700">If you see this box, the page loaded. Open browser console (F12) and type: <code>liveSocket</code></p>
        <p class="text-sm text-red-700">Check for errors in console. The page should auto-update when you click buttons.</p>
      </div>
      
      <div class="md:grid md:grid-cols-3 md:gap-6">
        <div class="md:col-span-1">
          <h3 class="text-lg font-medium leading-6 text-gray-900">YouTube API Settings</h3>
          <p class="mt-1 text-sm text-gray-500">
            Configure your YouTube Data API v3 key to enable fetching channel and video information.
          </p>
          <div class="mt-4 text-sm text-gray-600">
            <p class="font-medium">How to get an API key:</p>
            <ol class="list-decimal list-inside mt-2 space-y-1">
              <li>Go to <a href="https://console.cloud.google.com" target="_blank" class="text-indigo-600 hover:text-indigo-500">Google Cloud Console</a></li>
              <li>Create a new project or select existing</li>
              <li>Enable YouTube Data API v3</li>
              <li>Create credentials (API key)</li>
              <li>Copy and paste the key below</li>
            </ol>
          </div>
        </div>

        <div class="mt-5 md:mt-0 md:col-span-2">
          <.form for={@form} phx-submit="save" phx-change="validate">
            <div class="shadow sm:rounded-md sm:overflow-hidden">
              <div class="px-4 py-5 bg-white space-y-6 sm:p-6">
                <div>
                  <label for="api_key" class="block text-sm font-medium text-gray-700">
                    YouTube API Key
                  </label>
                  <div class="mt-1">
                    <input
                      type="text"
                      name="api_key"
                      id="api_key"
                      value={@api_key}
                      placeholder="AIzaSy..."
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  <p class="mt-2 text-sm text-gray-500">
                    Current status: 
                    <span class={[
                      "font-medium",
                      if(@api_key_valid?, do: "text-green-600", else: "text-red-600")
                    ]}>
                      <%= if @api_key_valid?, do: "✓ Configured", else: "✗ Not configured" %>
                    </span>
                  </p>
                </div>

                <%= if @test_result do %>
                  <div class={[
                    "rounded-md p-4",
                    if(@test_result.success, do: "bg-green-50", else: "bg-red-50")
                  ]}>
                    <div class="flex">
                      <div class="ml-3">
                        <h3 class={[
                          "text-sm font-medium",
                          if(@test_result.success, do: "text-green-800", else: "text-red-800")
                        ]}>
                          <%= @test_result.message %>
                        </h3>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
                <button
                  type="submit"
                  class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Save
                </button>
              </div>
            </div>
          </.form>

          <!-- Test API Key button OUTSIDE the form -->
          <div class="mt-4 shadow sm:rounded-md sm:overflow-hidden bg-yellow-50">
            <div class="px-4 py-3 sm:px-6 space-y-3">
              <p class="text-sm text-gray-700">
                Debug Info: testing=<%= inspect(@testing) %>, api_key_length=<%= String.length(@api_key || "") %>
              </p>
              
              <div class="mb-3 p-3 bg-blue-100 border border-blue-400 rounded">
                <p class="font-bold text-blue-800">JavaScript Test:</p>
                <button 
                  onclick="alert('JavaScript works! Now check if LiveView is connected by typing: liveSocket.isConnected() in console (F12)'); console.log('Button clicked!', window.liveSocket)"
                  class="mt-2 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
                >
                  Test JavaScript (Should show alert)
                </button>
              </div>
              
              <div class="flex gap-3">
                <button
                  phx-click="test_api_key"
                  class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <%= if @testing do %>
                    <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Testing...
                  <% else %>
                    Test API Key
                  <% end %>
                </button>
                
                <button
                  phx-click="simple_test"
                  class="inline-flex justify-center py-2 px-4 border border-green-500 shadow-sm text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                >
                  Simple Test Button
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- API Keys Management Section -->
      <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
          <div class="md:col-span-1">
            <h3 class="text-lg font-medium leading-6 text-gray-900">API Keys</h3>
            <p class="mt-1 text-sm text-gray-500">
              Create and manage API keys for accessing your data from third-party applications.
            </p>
          </div>

          <div class="mt-5 md:mt-0 md:col-span-2">
            <div class="shadow sm:rounded-md sm:overflow-hidden">
              <div class="px-4 py-5 bg-white space-y-6 sm:p-6">
                <!-- Create New API Key -->
                <div class="border-b border-gray-200 pb-4">
                  <h4 class="text-sm font-medium text-gray-900 mb-3">Create New API Key</h4>
                  <form phx-submit="create_api_key" class="flex items-end space-x-3">
                    <div class="flex-1">
                      <label for="api_key_name" class="block text-xs font-medium text-gray-700">
                        Key Name
                      </label>
                      <input
                        type="text"
                        name="name"
                        id="api_key_name"
                        placeholder="e.g., My App, Production Server"
                        required
                        class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                      />
                    </div>
                    <button
                      type="submit"
                      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Create Key
                    </button>
                  </form>
                </div>

                <!-- New API Key Display (shown once after creation) -->
                <%= if @new_api_key do %>
                  <div class="bg-green-50 border-l-4 border-green-400 p-4">
                    <div class="flex">
                      <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-green-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                      </div>
                      <div class="ml-3 flex-1">
                        <p class="text-sm font-medium text-green-800">
                          API Key Created Successfully!
                        </p>
                        <p class="mt-2 text-xs text-green-700">
                          <strong>Important:</strong> Copy this key now. You won't be able to see it again!
                        </p>
                        <div class="mt-3 flex items-center space-x-2">
                          <code class="flex-1 text-sm bg-white px-3 py-2 rounded border border-green-200 font-mono break-all">
                            <%= @new_api_key %>
                          </code>
                          <button
                            onclick={"navigator.clipboard.writeText('#{@new_api_key}')"}
                            class="px-3 py-2 text-xs font-medium text-green-700 bg-white border border-green-300 rounded hover:bg-green-50"
                          >
                            Copy
                          </button>
                        </div>
                        <button
                          phx-click="dismiss_new_key"
                          class="mt-3 text-xs text-green-700 hover:text-green-600 underline"
                        >
                          I've copied the key, dismiss this message
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>

                <!-- Existing API Keys -->
                <div>
                  <h4 class="text-sm font-medium text-gray-900 mb-3">Your API Keys</h4>
                  <%= if length(@api_keys) > 0 do %>
                    <div class="space-y-3">
                      <%= for api_key <- @api_keys do %>
                        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-200">
                          <div class="flex-1">
                            <div class="flex items-center space-x-2">
                              <p class="text-sm font-medium text-gray-900"><%= api_key.name %></p>
                              <%= if api_key.active do %>
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                                  Active
                                </span>
                              <% else %>
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                                  Inactive
                                </span>
                              <% end %>
                            </div>
                            <p class="mt-1 text-xs text-gray-500">
                              Key: <%= api_key.key_prefix %>***
                            </p>
                            <p class="text-xs text-gray-500">
                              Created: <%= Calendar.strftime(api_key.inserted_at, "%b %d, %Y") %>
                              <%= if api_key.last_used_at do %>
                                | Last used: <%= Calendar.strftime(api_key.last_used_at, "%b %d, %Y") %>
                              <% else %>
                                | Never used
                              <% end %>
                            </p>
                          </div>
                          <button
                            phx-click="delete_api_key"
                            phx-value-id={api_key.id}
                            data-confirm="Are you sure you want to delete this API key? This action cannot be undone."
                            class="ml-4 inline-flex items-center px-3 py-2 border border-red-300 text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
                          >
                            Delete
                          </button>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <p class="text-sm text-gray-500">No API keys created yet.</p>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-10 sm:mt-0">
        <div class="md:grid md:grid-cols-3 md:gap-6">
          <div class="md:col-span-1">
            <h3 class="text-lg font-medium leading-6 text-gray-900">Account Settings</h3>
            <p class="mt-1 text-sm text-gray-500">
              Manage your account preferences.
            </p>
          </div>

          <div class="mt-5 md:mt-0 md:col-span-2">
            <div class="shadow sm:rounded-md sm:overflow-hidden">
              <div class="px-4 py-5 bg-white space-y-6 sm:p-6">
                <div class="grid grid-cols-3 gap-6">
                  <div class="col-span-3 sm:col-span-2">
                    <label class="block text-sm font-medium text-gray-700">Email</label>
                    <div class="mt-1 text-sm text-gray-900"><%= @current_user.email %></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6">
        <.link navigate={~p"/"} class="text-sm text-indigo-600 hover:text-indigo-500">
          ← Back to Dashboard
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, session, socket) do
    require Logger
    Logger.warning("🔵 SETTINGS LIVEVIEW MOUNTING...")
    
    current_user = get_current_user(session)

    if current_user do
      Logger.warning("🔵 User authenticated: #{current_user.email}")
      
      # Load YouTube API key from database instead of application config
      api_key = Settings.get_value(current_user.tenant_id, "youtube_api_key") || ""
      api_key_valid? = api_key not in [nil, "", "YOUR_API_KEY_HERE"]
      
      # Load API keys for this user's tenant
      api_keys = ApiAuth.list_api_keys(current_user.tenant_id)

      socket =
        socket
        |> assign(:current_user, current_user)
        |> assign(:api_key, api_key)
        |> assign(:api_key_valid?, api_key_valid?)
        |> assign(:test_result, nil)
        |> assign(:testing, false)
        |> assign(:page_title, "Settings")
        |> assign(:api_keys, api_keys)
        |> assign(:new_api_key, nil)
        |> assign_form()

      Logger.warning("🔵 Settings LiveView mounted successfully!")
      {:ok, socket}
    else
      Logger.warning("🔵 User not authenticated, redirecting to login")
      {:ok, push_navigate(socket, to: ~p"/login")}
    end
  end

  def handle_event("validate", %{"api_key" => api_key}, socket) do
    api_key_valid? = api_key not in [nil, "", "YOUR_API_KEY_HERE"]
    
    socket =
      socket
      |> assign(:api_key, api_key)
      |> assign(:api_key_valid?, api_key_valid?)
    
    {:noreply, socket}
  end

  def handle_event("validate", params, socket) do
    require Logger
    Logger.debug("Validate params: #{inspect(params)}")
    {:noreply, socket}
  end

  def handle_event("save", %{"api_key" => api_key}, socket) do
    tenant_id = socket.assigns.current_user.tenant_id
    
    # Save to database instead of application config
    case Settings.set_setting(tenant_id, "youtube_api_key", api_key, 
           description: "YouTube Data API v3 Key") do
      {:ok, _setting} ->
        # Also set in application config for current session
        Application.put_env(:yt_tracker, :youtube_api_key, api_key)
        
        api_key_valid? = api_key not in [nil, "", "YOUR_API_KEY_HERE"]

        socket =
          socket
          |> assign(:api_key, api_key)
          |> assign(:api_key_valid?, api_key_valid?)
          |> put_flash(:info, "YouTube API key saved successfully!")

        {:noreply, socket}
      
      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Failed to save API key")
        
        {:noreply, socket}
    end
  end

  def handle_event("simple_test", _params, socket) do
    require Logger
    Logger.warning("========================================")
    Logger.warning("🎯 SIMPLE TEST BUTTON CLICKED!")
    Logger.warning("========================================")
    
    {:noreply, socket |> put_flash(:info, "Simple test button works!")}
  end

  def handle_event("test_api_key", params, socket) do
    require Logger
    Logger.warning("========================================")
    Logger.warning("TEST API KEY BUTTON CLICKED!")
    Logger.warning("Params: #{inspect(params)}")
    Logger.warning("Current API key: #{inspect(socket.assigns.api_key)}")
    Logger.warning("========================================")
    
    # Immediate feedback
    socket = put_flash(socket, :info, "Button clicked! Check terminal for logs.")
    
    {:noreply, socket}
  end
  
  def handle_info(:run_api_test, socket) do
    require Logger
    api_key = socket.assigns.api_key
    
    if api_key in [nil, "", "YOUR_API_KEY_HERE"] do
      result = %{success: false, message: "✗ Please enter an API key first"}
      Logger.info("Test result: #{inspect(result)}")
      {:noreply, socket |> assign(:test_result, result) |> assign(:testing, false)}
    else
      # Temporarily set the API key for testing
      original_key = Application.get_env(:yt_tracker, :youtube_api_key)
      Application.put_env(:yt_tracker, :youtube_api_key, api_key)
      
      Logger.info("Making test request to YouTube API...")
      
      # Test the API key by making a simple request
      result = case YtTracker.YoutubeApi.get_channel("UC_x5XG1OV2P6uZZ5FSM9Ttw") do # Google Developers channel
        {:ok, channel} ->
          Logger.info("API test successful! Channel: #{inspect(channel["title"])}")
          %{success: true, message: "✓ API key is valid and working!"}
        
        {:error, :api_key_not_configured} ->
          Logger.warning("API key not configured error")
          %{success: false, message: "✗ API key not configured"}
        
        {:error, reason} ->
          Logger.error("API test failed: #{inspect(reason)}")
          %{success: false, message: "✗ API key test failed: #{inspect(reason)}"}
      end
      
      Logger.info("Final test result: #{inspect(result)}")
      
      # Restore original key if it wasn't saved
      Application.put_env(:yt_tracker, :youtube_api_key, original_key)
      
      {:noreply, socket |> assign(:test_result, result) |> assign(:testing, false)}
    end
  end

  def handle_event("create_api_key", %{"name" => name}, socket) do
    tenant_id = socket.assigns.current_user.tenant_id
    
    case ApiAuth.create_api_key(%{
      tenant_id: tenant_id,
      name: name,
      active: true
    }) do
      {:ok, _api_key, key} ->
        # Reload API keys list
        api_keys = ApiAuth.list_api_keys(tenant_id)
        
        socket =
          socket
          |> assign(:api_keys, api_keys)
          |> assign(:new_api_key, key)
          |> put_flash(:info, "API key created successfully! Make sure to copy it now.")
        
        {:noreply, socket}
      
      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to create API key")
        
        {:noreply, socket}
    end
  end

  def handle_event("delete_api_key", %{"id" => id}, socket) do
    tenant_id = socket.assigns.current_user.tenant_id
    
    api_key = ApiAuth.get_api_key!(tenant_id, id)
    
    case ApiAuth.delete_api_key(api_key) do
      {:ok, _} ->
        # Reload API keys list
        api_keys = ApiAuth.list_api_keys(tenant_id)
        
        socket =
          socket
          |> assign(:api_keys, api_keys)
          |> put_flash(:info, "API key deleted successfully")
        
        {:noreply, socket}
      
      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Failed to delete API key")
        
        {:noreply, socket}
    end
  end

  def handle_event("dismiss_new_key", _params, socket) do
    {:noreply, assign(socket, :new_api_key, nil)}
  end

  defp get_current_user(session) do
    if user_token = session["user_token"] do
      YtTracker.Accounts.get_user_by_session_token(user_token)
    end
  end

  defp assign_form(socket) do
    assign(socket, :form, to_form(%{}))
  end
end
