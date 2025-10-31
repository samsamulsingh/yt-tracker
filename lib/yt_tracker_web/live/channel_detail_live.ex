defmodule YtTrackerWeb.ChannelDetailLive do
  use YtTrackerWeb, :live_view
  alias YtTracker.{Channels, Repo}
  import Ecto.Query

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
      <%= if @channel do %>
        <!-- Channel Header -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-6">
          <div class="px-4 py-5 sm:px-6 flex items-center space-x-4">
            <%= if @channel[:thumbnail_url] do %>
              <img src={@channel[:thumbnail_url]} alt={@channel[:title]} class="h-20 w-20 rounded-full" />
            <% end %>
            <div class="flex-1">
              <h1 class="text-2xl font-bold text-gray-900"><%= @channel[:title] %></h1>
              <p class="mt-1 text-sm text-gray-500">
                Channel ID: <code class="bg-gray-100 px-2 py-1 rounded"><%= @channel[:youtube_id] %></code>
              </p>
              <%= if @channel[:rss_url] do %>
                <p class="mt-1 text-sm text-gray-500">
                  RSS Feed: <a href={@channel[:rss_url]} target="_blank" class="text-indigo-600 hover:text-indigo-500 underline"><%= @channel[:rss_url] %></a>
                </p>
              <% end %>
              <%= if @channel[:last_api_sync_at] do %>
                <p class="mt-1 text-xs text-gray-400">
                  Last API Sync: <%= format_time_ago(@channel[:last_api_sync_at]) %>
                </p>
              <% end %>
              <div class="mt-2 flex items-center space-x-4">
                <span class={[
                  "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                  if(@channel[:monitor], do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800")
                ]}>
                  <%= if @channel[:monitor], do: "Monitoring Active", else: "Monitoring Disabled" %>
                </span>
                
                <%= if @channel[:monitor] do %>
                  <button
                    phx-click="disable_monitoring"
                    class="text-sm text-red-600 hover:text-red-500"
                  >
                    Disable Monitoring
                  </button>
                  
                  <div class="flex items-center space-x-2">
                    <span class="text-xs text-gray-500">RSS Check:</span>
                    <form phx-change="update_frequency">
                      <select
                        name="frequency"
                        class="text-xs border-gray-300 rounded-md"
                      >
                        <%= for {label, value} <- [{"5 min", 5}, {"15 min", 15}, {"30 min", 30}, {"1 hour", 60}, {"2 hours", 120}, {"6 hours", 360}] do %>
                          <option value={value} selected={@channel[:monitor].check_frequency_minutes == value}>
                            <%= label %>
                          </option>
                        <% end %>
                      </select>
                    </form>
                  </div>
                <% else %>
                  <button
                    phx-click="enable_monitoring"
                    class="text-sm text-green-600 hover:text-green-500"
                  >
                    Enable Monitoring
                  </button>
                <% end %>
              </div>
            </div>
            <div class="text-right">
              <.link navigate={~p"/"} class="text-sm text-indigo-600 hover:text-indigo-500">
                ← Back to Dashboard
              </.link>
            </div>
          </div>
        </div>

        <!-- Statistics Cards -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-3 mb-6">
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <dt class="text-sm font-medium text-gray-500 truncate">Total Videos (YouTube)</dt>
              <dd class="mt-1 text-3xl font-semibold text-gray-900">
                <%= @stats.total_youtube_videos %>
              </dd>
            </div>
          </div>

          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <dt class="text-sm font-medium text-gray-500 truncate">Videos in Database</dt>
              <dd class="mt-1 text-3xl font-semibold text-gray-900">
                <%= @stats.videos_in_db %>
              </dd>
            </div>
          </div>

          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <dt class="text-sm font-medium text-gray-500 truncate">Coverage</dt>
              <dd class="mt-1 text-3xl font-semibold text-gray-900">
                <%= @stats.coverage_percent %>%
              </dd>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="mb-6 flex space-x-4">
          <button
            phx-click="refresh_channel"
            class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg class="-ml-1 mr-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh Channel Info
          </button>
          
          <button
            phx-click="sync_channel"
            disabled={@sync_status != nil}
            class={[
              "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
              if(@sync_status, do: "bg-gray-400 cursor-not-allowed", else: "bg-indigo-600 hover:bg-indigo-700")
            ]}
          >
            <svg class="-ml-1 mr-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            <%= if @sync_status, do: "Syncing...", else: "Sync Videos (API)" %>
          </button>

          <button
            phx-click="force_rss_fetch"
            class="inline-flex items-center px-4 py-2 border border-green-300 text-sm font-medium rounded-md shadow-sm text-green-700 bg-white hover:bg-green-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
          >
            <svg class="-ml-1 mr-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 5c7.18 0 13 5.82 13 13M6 11a7 7 0 017 7m-6 0a1 1 0 11-2 0 1 1 0 012 0z" />
            </svg>
            Force RSS Fetch
          </button>
        </div>

        <!-- Sync Progress Bar -->
        <%= if @sync_status do %>
          <div class="mb-6 bg-white shadow sm:rounded-lg p-6">
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center space-x-2">
                <svg class="animate-spin h-5 w-5 text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span class="text-sm font-medium text-gray-900">
                  <%= String.capitalize(@sync_status) %>: <%= @sync_progress %> / <%= @sync_total %> videos
                </span>
              </div>
              <span class="text-sm text-gray-500">
                <%= if @sync_total > 0, do: "#{round(@sync_progress / @sync_total * 100)}%", else: "0%" %>
              </span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2.5">
              <div 
                class="bg-indigo-600 h-2.5 rounded-full transition-all duration-300" 
                style={"width: #{if @sync_total > 0, do: (@sync_progress / @sync_total * 100), else: 0}%"}
              >
              </div>
            </div>
            <p class="mt-2 text-xs text-gray-500">
              Please wait while we fetch videos from YouTube. This may take a few minutes for channels with many videos.
            </p>
          </div>
        <% end %>

        <!-- Tab Navigation -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="border-b border-gray-200">
            <nav class="-mb-px flex space-x-8 px-6" aria-label="Tabs">
              <button
                phx-click="switch_tab"
                phx-value-tab="videos"
                class={[
                  "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                  if(@active_tab == "videos", 
                    do: "border-indigo-500 text-indigo-600", 
                    else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
                ]}
              >
                Videos
                <span class={[
                  "ml-2 py-0.5 px-2.5 rounded-full text-xs font-medium",
                  if(@active_tab == "videos", 
                    do: "bg-indigo-100 text-indigo-600", 
                    else: "bg-gray-100 text-gray-900")
                ]}>
                  <%= @stats.videos_in_db %>
                </span>
              </button>
              
              <button
                phx-click="switch_tab"
                phx-value-tab="sync_logs"
                class={[
                  "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                  if(@active_tab == "sync_logs", 
                    do: "border-indigo-500 text-indigo-600", 
                    else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
                ]}
              >
                Sync Logs
              </button>
              
              <button
                phx-click="switch_tab"
                phx-value-tab="api"
                class={[
                  "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm",
                  if(@active_tab == "api", 
                    do: "border-indigo-500 text-indigo-600", 
                    else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")
                ]}
              >
                API
              </button>
            </nav>
          </div>

          <!-- Tab Content -->
          <%= if @active_tab == "videos" do %>
            <!-- Videos Table -->
            <div>
              <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
                <h2 class="text-lg font-medium text-gray-900">Videos</h2>
                <p class="mt-1 text-sm text-gray-500">
                  Showing <%= length(@videos) %> of <%= @stats.videos_in_db %> videos
                </p>
              </div>

              <%= if length(@videos) > 0 do %>
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Video
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Published
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Source
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for video <- @videos do %>
                      <tr>
                        <td class="px-6 py-4">
                          <div class="flex items-center">
                            <%= if video.thumbnail_url do %>
                              <img src={video.thumbnail_url} alt={video.title || video.youtube_id} class="h-16 w-28 object-cover rounded" />
                            <% end %>
                            <div class="ml-4">
                              <div class="text-sm font-medium text-gray-900"><%= video.title || video.youtube_id %></div>
                              <div class="text-sm text-gray-500">
                                <code class="text-xs"><%= video.youtube_id %></code>
                              </div>
                            </div>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <%= if video.published_at do %>
                            <%= Calendar.strftime(video.published_at, "%b %d, %Y") %>
                          <% else %>
                            -
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={[
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full",
                            case video.source do
                              "api" -> "bg-blue-100 text-blue-800"
                              "rss" -> "bg-green-100 text-green-800"
                              "scraping" -> "bg-purple-100 text-purple-800"
                              _ -> "bg-gray-100 text-gray-800"
                            end
                          ]}>
                            <%= String.upcase(video.source || "API") %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <a
                            href={"https://youtube.com/watch?v=#{video.youtube_id}"}
                            target="_blank"
                            class="text-indigo-600 hover:text-indigo-900"
                          >
                            Watch
                          </a>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>

            <!-- Pagination -->
            <%= if @total_pages > 1 do %>
              <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                <div class="flex-1 flex justify-between sm:hidden">
                  <%= if @page > 1 do %>
                    <button
                      phx-click="prev_page"
                      class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                    >
                      Previous
                    </button>
                  <% end %>
                  <%= if @page < @total_pages do %>
                    <button
                      phx-click="next_page"
                      class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                    >
                      Next
                    </button>
                  <% end %>
                </div>
                <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing page <span class="font-medium"><%= @page %></span> of <span class="font-medium"><%= @total_pages %></span>
                    </p>
                  </div>
                  <div>
                    <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                      <%= if @page > 1 do %>
                        <button
                          phx-click="prev_page"
                          class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                        >
                          Previous
                        </button>
                      <% end %>
                      <%= if @page < @total_pages do %>
                        <button
                          phx-click="next_page"
                          class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                        >
                          Next
                        </button>
                      <% end %>
                    </nav>
                  </div>
                </div>
              </div>
            <% end %>
          <% else %>
            <div class="px-6 py-12 text-center">
              <p class="text-sm text-gray-500">No videos found for this channel.</p>
              <button
                phx-click="sync_channel"
                class="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Sync Videos Now
              </button>
            </div>
          <% end %>
            </div>
          <% end %>
          
          <%= if @active_tab == "sync_logs" do %>
            <!-- Sync Logs Tab -->
            <div>
              <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
                <h2 class="text-lg font-medium text-gray-900">Sync Logs</h2>
                <p class="mt-1 text-sm text-gray-500">
                  History of API and RSS sync operations
                </p>
              </div>

              <%= if length(@sync_logs || []) > 0 do %>
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Type
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Status
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Videos
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Started
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Duration
                      </th>
                      <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Details
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for log <- @sync_logs do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={[
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full",
                            case log.sync_type do
                              "api" -> "bg-blue-100 text-blue-800"
                              "rss" -> "bg-green-100 text-green-800"
                              "scraping" -> "bg-purple-100 text-purple-800"
                              _ -> "bg-gray-100 text-gray-800"
                            end
                          ]}>
                            <%= String.upcase(log.sync_type) %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={[
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full",
                            case log.status do
                              "success" -> "bg-green-100 text-green-800"
                              "failed" -> "bg-red-100 text-red-800"
                              "in_progress" -> "bg-yellow-100 text-yellow-800"
                              _ -> "bg-gray-100 text-gray-800"
                            end
                          ]}>
                            <%= if log.status == "in_progress", do: "In Progress", else: String.capitalize(log.status) %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          <%= log.videos_fetched || 0 %> fetched
                          <div class="text-xs text-gray-500">
                            <%= log.videos_new || 0 %> new, <%= log.videos_updated || 0 %> updated
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <%= if log.started_at do %>
                            <%= Calendar.strftime(log.started_at, "%b %d, %Y %H:%M") %>
                          <% else %>
                            -
                          <% end %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <%= if log.completed_at && log.started_at do %>
                            <%= format_duration(log.started_at, log.completed_at) %>
                          <% else %>
                            <%= if log.status == "in_progress", do: "In progress...", else: "-" %>
                          <% end %>
                        </td>
                        <td class="px-6 py-4 text-sm text-gray-500">
                          <%= if log.error_message do %>
                            <span class="text-red-600 truncate block max-w-xs" title={log.error_message}>
                              <%= String.slice(log.error_message, 0..50) %><%= if String.length(log.error_message) > 50, do: "..." %>
                            </span>
                          <% else %>
                            <%= if log.metadata && log.metadata["not_modified"] do %>
                              <span class="text-gray-400">Not modified</span>
                            <% else %>
                              -
                            <% end %>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>

                <!-- Pagination for Sync Logs -->
                <%= if @sync_logs_total_pages > 1 do %>
                  <div class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
                    <div class="flex-1 flex justify-between sm:hidden">
                      <%= if @sync_logs_page > 1 do %>
                        <button
                          phx-click="sync_logs_prev_page"
                          class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                        >
                          Previous
                        </button>
                      <% end %>
                      <%= if @sync_logs_page < @sync_logs_total_pages do %>
                        <button
                          phx-click="sync_logs_next_page"
                          class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                        >
                          Next
                        </button>
                      <% end %>
                    </div>
                    <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                      <div>
                        <p class="text-sm text-gray-700">
                          Showing page <span class="font-medium"><%= @sync_logs_page %></span> of <span class="font-medium"><%= @sync_logs_total_pages %></span>
                        </p>
                      </div>
                      <div>
                        <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                          <%= if @sync_logs_page > 1 do %>
                            <button
                              phx-click="sync_logs_prev_page"
                              class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                            >
                              Previous
                            </button>
                          <% end %>
                          <%= if @sync_logs_page < @sync_logs_total_pages do %>
                            <button
                              phx-click="sync_logs_next_page"
                              class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                            >
                              Next
                            </button>
                          <% end %>
                        </nav>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% else %>
                <div class="px-6 py-12 text-center">
                  <p class="text-sm text-gray-500">No sync logs found for this channel.</p>
                  <p class="mt-2 text-xs text-gray-400">Sync logs will appear here after running API or RSS syncs.</p>
                </div>
              <% end %>
            </div>
          <% end %>
          
          <%= if @active_tab == "api" do %>
            <!-- API Tab -->
            <div>
              <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
                <h2 class="text-lg font-medium text-gray-900">API Endpoints</h2>
                <p class="mt-1 text-sm text-gray-500">
                  Use these URLs to access channel data from third-party applications
                </p>
              </div>
              
              <div class="px-6 py-6 space-y-6">
                <!-- API Key Section -->
                <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4">
                  <div class="flex">
                    <div class="flex-shrink-0">
                      <svg class="h-5 w-5 text-yellow-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                      </svg>
                    </div>
                    <div class="ml-3">
                      <p class="text-sm text-yellow-700">
                        <strong>Authentication Required:</strong> You need an API key to access these endpoints.
                        <.link navigate={~p"/settings"} class="font-medium underline text-yellow-700 hover:text-yellow-600">
                          Create an API key in Settings →
                        </.link>
                      </p>
                    </div>
                  </div>
                </div>

                <!-- Get Channel Info -->
                <div class="bg-white border border-gray-200 rounded-lg">
                  <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 rounded-t-lg">
                    <h3 class="text-sm font-medium text-gray-900">Get Channel Information</h3>
                  </div>
                  <div class="px-4 py-4 space-y-3">
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Endpoint</label>
                      <div class="flex items-center space-x-2">
                        <code class="flex-1 text-sm bg-gray-100 px-3 py-2 rounded border border-gray-300 font-mono">
                          GET <%= YtTrackerWeb.Endpoint.url() %>/api/v1/channels/<%= @channel[:youtube_id] %>
                        </code>
                        <button
                          onclick={"navigator.clipboard.writeText('#{YtTrackerWeb.Endpoint.url()}/api/v1/channels/#{@channel[:youtube_id]}')"}
                          class="px-3 py-2 text-xs font-medium text-gray-700 bg-white border border-gray-300 rounded hover:bg-gray-50"
                        >
                          Copy
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Headers</label>
                      <code class="block text-sm bg-gray-100 px-3 py-2 rounded border border-gray-300 font-mono">
                        X-API-Key: your_api_key_here
                      </code>
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Response</label>
                      <pre class="text-xs bg-gray-900 text-green-400 px-3 py-2 rounded overflow-x-auto"><code>{
  "data": {
    "id": "<%= @channel[:youtube_id] %>",
    "title": "<%= @channel[:title] %>",
    "description": "...",
    "subscriber_count": <%= @channel[:subscriber_count] || 0 %>,
    "video_count": <%= @stats.videos_in_db %>,
    "thumbnail_url": "<%= @channel[:thumbnail_url] %>",
    "custom_url": "<%= @channel[:custom_url] %>"
  }
}</code></pre>
                    </div>
                  </div>
                </div>

                <!-- Get Channel Videos -->
                <div class="bg-white border border-gray-200 rounded-lg">
                  <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 rounded-t-lg">
                    <h3 class="text-sm font-medium text-gray-900">Get Channel Videos</h3>
                  </div>
                  <div class="px-4 py-4 space-y-3">
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Endpoint</label>
                      <div class="flex items-center space-x-2">
                        <code class="flex-1 text-sm bg-gray-100 px-3 py-2 rounded border border-gray-300 font-mono">
                          GET <%= YtTrackerWeb.Endpoint.url() %>/api/v1/channels/<%= @channel[:youtube_id] %>/videos
                        </code>
                        <button
                          onclick={"navigator.clipboard.writeText('#{YtTrackerWeb.Endpoint.url()}/api/v1/channels/#{@channel[:youtube_id]}/videos')"}
                          class="px-3 py-2 text-xs font-medium text-gray-700 bg-white border border-gray-300 rounded hover:bg-gray-50"
                        >
                          Copy
                        </button>
                      </div>
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Headers</label>
                      <code class="block text-sm bg-gray-100 px-3 py-2 rounded border border-gray-300 font-mono">
                        X-API-Key: your_api_key_here
                      </code>
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Query Parameters (Optional)</label>
                      <div class="text-xs space-y-1">
                        <div><code class="bg-gray-100 px-2 py-1 rounded">page</code> - Page number (default: 1)</div>
                        <div><code class="bg-gray-100 px-2 py-1 rounded">per_page</code> - Items per page (default: 20, max: 100)</div>
                      </div>
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Response</label>
                      <pre class="text-xs bg-gray-900 text-green-400 px-3 py-2 rounded overflow-x-auto"><code>{
  "data": [
    {
      "id": "video_youtube_id",
      "title": "Video Title",
      "description": "...",
      "published_at": "2025-10-30T15:05:29Z",
      "thumbnail_url": "https://...",
      "duration": "PT7M25S",
      "view_count": 259,
      "like_count": 50,
      "comment_count": 12
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total_count": <%= @stats.videos_in_db %>
  }
}</code></pre>
                    </div>
                  </div>
                </div>

                <!-- cURL Examples -->
                <div class="bg-white border border-gray-200 rounded-lg">
                  <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 rounded-t-lg">
                    <h3 class="text-sm font-medium text-gray-900">cURL Examples</h3>
                  </div>
                  <div class="px-4 py-4 space-y-3">
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Get Channel</label>
                      <pre class="text-xs bg-gray-900 text-green-400 px-3 py-2 rounded overflow-x-auto"><code>curl -X GET "<%= YtTrackerWeb.Endpoint.url() %>/api/v1/channels/<%= @channel[:youtube_id] %>" \
  -H "X-API-Key: your_api_key_here"</code></pre>
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-500 uppercase mb-1">Get Videos (Paginated)</label>
                      <pre class="text-xs bg-gray-900 text-green-400 px-3 py-2 rounded overflow-x-auto"><code>curl -X GET "<%= YtTrackerWeb.Endpoint.url() %>/api/v1/channels/<%= @channel[:youtube_id] %>/videos?page=1&per_page=20" \
  -H "X-API-Key: your_api_key_here"</code></pre>
                    </div>
                  </div>
                </div>

                <!-- Documentation Link -->
                <div class="text-center pt-4">
                  <p class="text-sm text-gray-500">
                    For complete API documentation, visit 
                    <a href="/api/docs" class="text-indigo-600 hover:text-indigo-500 font-medium">API Documentation</a>
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-12">
          <p class="text-gray-500">Channel not found.</p>
          <.link navigate={~p"/"} class="mt-4 inline-block text-indigo-600 hover:text-indigo-500">
            Back to Dashboard
          </.link>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(%{"youtube_id" => youtube_id}, session, socket) do
    current_user = get_current_user(session)

    if current_user do
      # Clear any existing flash messages immediately
      socket = clear_flash(socket)
      
      try do
        require Logger
        Logger.info("Loading channel #{youtube_id} for user #{current_user.id}")
        channel = load_channel_by_youtube_id(youtube_id, current_user.id)
        Logger.info("Channel loaded: #{inspect(channel != nil)}")
        
        if channel do
          # Subscribe to sync progress updates for this channel
          Phoenix.PubSub.subscribe(YtTracker.PubSub, "channel:#{channel.id}:sync")
          
          stats = calculate_stats(channel)
          
          # Convert channel to map and preserve the monitor association
          channel_map = Map.from_struct(channel)
          
          # Ensure RSS URL is set (generate if missing)
          channel_map = if channel_map[:rss_url] do
            channel_map
          else
            Map.put(channel_map, :rss_url, YtTracker.Channels.YoutubeChannel.rss_url(channel.youtube_id))
          end
          
          socket =
            socket
            |> assign(:current_user, current_user)
            |> assign(:channel, channel_map)
            |> assign(:stats, stats)
            |> assign(:page, 1)
            |> assign(:per_page, 20)
            |> assign(:page_title, channel.title || "Channel Details")
            |> assign(:sync_status, nil)
            |> assign(:sync_progress, 0)
            |> assign(:sync_total, 0)
            |> assign(:active_tab, "videos")
            |> assign(:sync_logs, [])
            |> assign(:sync_logs_page, 1)
            |> assign(:sync_logs_total_pages, 1)
            |> load_videos()

          {:ok, socket}
        else
          {:ok,
           socket
           |> put_flash(:error, "Channel not found")
           |> push_navigate(to: ~p"/")}
        end
      rescue
        e ->
          require Logger
          Logger.error("Error mounting channel detail page: #{inspect(e)}")
          Logger.error("Stacktrace: #{inspect(__STACKTRACE__)}")
          
          {:ok,
           socket
           |> put_flash(:error, "Failed to load channel: #{Exception.message(e)}")
           |> push_navigate(to: ~p"/")}
      end
    else
      {:ok, push_navigate(socket, to: ~p"/login")}
    end
  end

  def handle_event("enable_monitoring", _params, socket) do
    channel_id = socket.assigns.channel[:id]
    
    case Channels.enable_monitoring(channel_id) do
      {:ok, _monitor} ->
        # Reload the channel with updated monitor
        channel = load_channel_by_youtube_id(socket.assigns.channel[:youtube_id], socket.assigns.current_user.id)
        
        socket =
          socket
          |> assign(:channel, Map.from_struct(channel))
          |> put_flash(:info, "Monitoring enabled for this channel")
        
        {:noreply, socket}
      
      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Failed to enable monitoring")
        
        {:noreply, socket}
    end
  end

  def handle_event("disable_monitoring", _params, socket) do
    channel_id = socket.assigns.channel[:id]
    
    case Channels.disable_monitoring(channel_id) do
      {:ok, _monitor} ->
        # Reload the channel with updated monitor
        channel = load_channel_by_youtube_id(socket.assigns.channel[:youtube_id], socket.assigns.current_user.id)
        
        socket =
          socket
          |> assign(:channel, Map.from_struct(channel))
          |> put_flash(:info, "Monitoring disabled for this channel")
        
        {:noreply, socket}
      
      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Failed to disable monitoring")
        
        {:noreply, socket}
    end
  end

  def handle_event("sync_channel", _params, socket) do
    require Logger
    Logger.warning("🟢 SYNC CHANNEL EVENT TRIGGERED")
    
    channel_id = socket.assigns.channel[:id]
    Logger.warning("🟢 Channel ID: #{inspect(channel_id)}")
    
    # Trigger background job to sync videos
    case Channels.get_channel(channel_id) do
      nil ->
        Logger.error("🔴 Channel not found: #{channel_id}")
        socket =
          socket
          |> put_flash(:error, "Channel not found")
        {:noreply, socket}
      
      channel ->
        Logger.warning("🟢 Channel found: #{inspect(channel.youtube_id)}")
        
        # Check if uploads_playlist_id exists
        if channel.uploads_playlist_id do
          # Queue a backfill job
          case %{channel_id: channel.id}
               |> YtTracker.Workers.BackfillChannel.new()
               |> Oban.insert() do
            {:ok, job} ->
              Logger.warning("🟢 Oban job queued successfully: #{inspect(job.id)}")
              socket =
                socket
                |> put_flash(:info, "Video sync started. This may take a few minutes.")
              
              {:noreply, socket}
            
            {:error, reason} ->
              Logger.error("🔴 Failed to queue Oban job: #{inspect(reason)}")
              socket =
                socket
                |> put_flash(:error, "Failed to start video sync: #{inspect(reason)}")
              
              {:noreply, socket}
          end
        else
          Logger.error("🔴 Channel has no uploads_playlist_id")
          socket =
            socket
            |> put_flash(:error, "Channel is missing uploads playlist ID. Please click 'Refresh Channel Info' first.")
          
          {:noreply, socket}
        end
    end
  end

  def handle_event("refresh_channel", _params, socket) do
    require Logger
    Logger.warning("🟢 REFRESH CHANNEL EVENT TRIGGERED")
    
    channel_id = socket.assigns.channel[:id]
    old_youtube_id = socket.assigns.channel[:youtube_id]
    
    case Channels.get_channel(channel_id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Channel not found")
        {:noreply, socket}
      
      channel ->
        case Channels.refresh_channel_data(channel) do
          {:ok, updated_channel} ->
            Logger.warning("🟢 Channel data refreshed successfully")
            
            # Reload the channel data by database ID (in case youtube_id changed)
            channel_data = Repo.get!(YtTracker.Channels.YoutubeChannel, channel_id)
            |> Repo.preload(:monitor)
            
            new_youtube_id = channel_data.youtube_id
            
            # If the youtube_id changed (e.g., from handle to UC ID), redirect to new URL
            if new_youtube_id != old_youtube_id do
              Logger.info("Channel ID changed from #{old_youtube_id} to #{new_youtube_id}, redirecting...")
              
              socket =
                socket
                |> put_flash(:info, "Channel information refreshed! Channel ID updated from #{old_youtube_id} to #{new_youtube_id}")
                |> push_navigate(to: ~p"/channels/#{new_youtube_id}")
              
              {:noreply, socket}
            else
              # Just refresh the data
              socket =
                socket
                |> put_flash(:info, "Channel information refreshed successfully!")
                |> assign(:channel, Map.from_struct(channel_data))
                |> assign(:stats, calculate_stats(channel_data))
                |> load_videos()
              
              {:noreply, socket}
            end
          
          {:error, reason} ->
            Logger.error("🔴 Failed to refresh channel data: #{inspect(reason)}")
            socket =
              socket
              |> put_flash(:error, "Failed to refresh channel data: #{inspect(reason)}")
            
            {:noreply, socket}
        end
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket =
      socket
      |> assign(:active_tab, tab)
      |> then(fn s ->
        if tab == "sync_logs" do
          load_sync_logs(s)
        else
          s
        end
      end)
    
    {:noreply, socket}
  end

  def handle_event("sync_logs_prev_page", _params, socket) do
    page = max(1, socket.assigns.sync_logs_page - 1)
    
    socket =
      socket
      |> assign(:sync_logs_page, page)
      |> load_sync_logs()
    
    {:noreply, socket}
  end

  def handle_event("sync_logs_next_page", _params, socket) do
    page = min(socket.assigns.sync_logs_total_pages, socket.assigns.sync_logs_page + 1)
    
    socket =
      socket
      |> assign(:sync_logs_page, page)
      |> load_sync_logs()
    
    {:noreply, socket}
  end

  def handle_event("prev_page", _params, socket) do
    page = max(1, socket.assigns.page - 1)
    
    socket =
      socket
      |> assign(:page, page)
      |> load_videos()
    
    {:noreply, socket}
  end

  def handle_event("next_page", _params, socket) do
    page = min(socket.assigns.total_pages, socket.assigns.page + 1)
    
    socket =
      socket
      |> assign(:page, page)
      |> load_videos()
    
    {:noreply, socket}
  end

  def handle_event("update_frequency", %{"frequency" => frequency}, socket) do
    require Logger
    channel_id = socket.assigns.channel[:id]
    frequency_int = String.to_integer(frequency)
    
    case Channels.update_monitor_frequency(channel_id, frequency_int) do
      {:ok, _monitor} ->
        # Reload channel
        channel = load_channel_by_youtube_id(socket.assigns.channel[:youtube_id], socket.assigns.current_user.id)
        
        socket =
          socket
          |> assign(:channel, Map.from_struct(channel))
          |> put_flash(:info, "RSS check frequency updated to #{frequency_label(frequency_int)}")
        
        {:noreply, socket}
      
      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Failed to update frequency")
        
        {:noreply, socket}
    end
  end

  def handle_event("force_rss_fetch", _params, socket) do
    require Logger
    channel_id = socket.assigns.channel[:id]
    
    Logger.info("Force RSS fetch triggered for channel #{channel_id}")
    
    # Queue RSS poll job immediately
    case %{channel_id: channel_id}
         |> YtTracker.Workers.PollRss.new(queue: :rss_poll)
         |> Oban.insert() do
      {:ok, _job} ->
        socket =
          socket
          |> put_flash(:info, "RSS fetch queued. New videos will appear shortly.")
        
        {:noreply, socket}
      
      {:error, reason} ->
        Logger.error("Failed to queue RSS poll: #{inspect(reason)}")
        socket =
          socket
          |> put_flash(:error, "Failed to queue RSS fetch")
        
        {:noreply, socket}
    end
  end

  # Handle sync progress updates from PubSub
  def handle_info({:sync_progress, status, progress, total}, socket) do
    socket =
      socket
      |> assign(:sync_status, status)
      |> assign(:sync_progress, progress)
      |> assign(:sync_total, total)
    
    {:noreply, socket}
  end

  def handle_info({:sync_complete, total_videos}, socket) do
    # Reload stats and videos
    channel = load_channel_by_youtube_id(socket.assigns.channel[:youtube_id], socket.assigns.current_user.id)
    
    socket =
      socket
      |> assign(:sync_status, "complete")
      |> assign(:sync_progress, total_videos)
      |> assign(:sync_total, total_videos)
      |> assign(:stats, calculate_stats(channel))
      |> load_videos()
      |> put_flash(:info, "Sync complete! Added #{total_videos} videos.")
    
    {:noreply, socket}
  end

  def handle_info({:sync_error, reason}, socket) do
    socket =
      socket
      |> assign(:sync_status, nil)
      |> assign(:sync_progress, 0)
      |> assign(:sync_total, 0)
      |> put_flash(:error, "Sync failed: #{reason}")
    
    {:noreply, socket}
  end

  defp get_current_user(session) do
    if user_token = session["user_token"] do
      YtTracker.Accounts.get_user_by_session_token(user_token)
    end
  end

  defp load_channel_by_youtube_id(youtube_id, user_id) do
    # First try to load channel for this user
    query =
      from c in YtTracker.Channels.YoutubeChannel,
        where: c.youtube_id == ^youtube_id and c.user_id == ^user_id,
        preload: [:monitor]
    
    case Repo.one(query) do
      nil ->
        # If not found for this user, try to load without user filter
        # (channel might not have user_id set)
        query =
          from c in YtTracker.Channels.YoutubeChannel,
            where: c.youtube_id == ^youtube_id,
            preload: [:monitor]
        
        Repo.one(query)
      
      channel ->
        channel
    end
  end

  defp calculate_stats(channel) do
    # Get video count from database
    videos_in_db =
      from(v in YtTracker.Channels.Video,
        where: v.channel_id == ^channel.id
      )
      |> Repo.aggregate(:count)
    
    # For now, use the video count from channel metadata or fallback to DB count
    # In a real app, you'd query YouTube API to get the actual count
    total_youtube_videos = channel.video_count || videos_in_db
    
    coverage_percent =
      if total_youtube_videos > 0 do
        round((videos_in_db / total_youtube_videos) * 100)
      else
        0
      end
    
    %{
      total_youtube_videos: total_youtube_videos,
      videos_in_db: videos_in_db,
      coverage_percent: coverage_percent
    }
  end

  defp load_videos(socket) do
    channel_id = socket.assigns.channel[:id]
    page = socket.assigns.page
    per_page = socket.assigns.per_page
    
    offset = (page - 1) * per_page
    
    # Get total count
    total_count =
      from(v in YtTracker.Channels.Video,
        where: v.channel_id == ^channel_id
      )
      |> Repo.aggregate(:count)
    
    total_pages = ceil(total_count / per_page)
    
    # Get videos for current page
    videos =
      from(v in YtTracker.Channels.Video,
        where: v.channel_id == ^channel_id,
        order_by: [desc: v.published_at],
        limit: ^per_page,
        offset: ^offset
      )
      |> Repo.all()
    
    socket
    |> assign(:videos, videos)
    |> assign(:total_pages, total_pages)
  end

  defp load_sync_logs(socket) do
    channel_id = socket.assigns.channel[:id]
    page = Map.get(socket.assigns, :sync_logs_page, 1)
    per_page = 20
    
    # Get sync logs for current channel
    sync_logs = Channels.list_sync_logs(channel_id, page: page, per_page: per_page)
    
    # Get total count for pagination
    total_count = Channels.count_sync_logs(channel_id)
    total_pages = max(1, ceil(total_count / per_page))
    
    socket
    |> assign(:sync_logs, sync_logs)
    |> assign(:sync_logs_page, page)
    |> assign(:sync_logs_total_pages, total_pages)
  end

  defp frequency_label(minutes) do
    case minutes do
      5 -> "5 minutes"
      15 -> "15 minutes"
      30 -> "30 minutes"
      60 -> "1 hour"
      120 -> "2 hours"
      360 -> "6 hours"
      _ -> "#{minutes} minutes"
    end
  end

  defp format_time_ago(datetime) when is_nil(datetime), do: "Never"
  
  defp format_time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)
    
    cond do
      diff < 60 -> "#{diff} seconds ago"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604800 -> "#{div(diff, 86400)} days ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y at %H:%M")
    end
  end

  defp format_duration(started_at, completed_at) do
    diff = DateTime.diff(completed_at, started_at, :second)
    
    cond do
      diff < 60 -> "#{diff}s"
      diff < 3600 -> "#{div(diff, 60)}m #{rem(diff, 60)}s"
      true -> "#{div(diff, 3600)}h #{div(rem(diff, 3600), 60)}m"
    end
  end
end
