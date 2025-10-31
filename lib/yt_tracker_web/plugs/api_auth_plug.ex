defmodule YtTrackerWeb.Plugs.ApiAuthPlug do
  @moduledoc """
  Authenticates API requests using Bearer token.
  """

  import Plug.Conn
  alias YtTracker.ApiAuth

  def init(opts), do: opts

  def call(conn, _opts) do
    token = 
      case get_req_header(conn, "authorization") do
        ["Bearer " <> token] -> token
        _ -> 
          case get_req_header(conn, "x-api-key") do
            [key] -> key
            _ -> nil
          end
      end

    case token do
      nil ->
        unauthorized(conn)
      
      token ->
        case ApiAuth.authenticate(token) do
          {:ok, api_key} ->
            conn
            |> assign(:api_key, api_key)
            |> assign(:tenant, api_key.tenant)
            |> assign(:tenant_id, api_key.tenant_id)
          
          {:error, _} ->
            unauthorized(conn)
        end
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{
      error: %{
        type: "unauthorized",
        title: "Unauthorized",
        detail: "Invalid or missing API key"
      }
    })
    |> halt()
  end
end
