defmodule YtTrackerWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by Phoenix for error responses.
  """

  def render("404.json", _assigns) do
    %{
      error: %{
        type: "not_found",
        title: "Not Found",
        detail: "The requested resource was not found",
        status: 404
      }
    }
  end

  def render("500.json", _assigns) do
    %{
      error: %{
        type: "internal_server_error",
        title: "Internal Server Error",
        detail: "An unexpected error occurred",
        status: 500
      }
    }
  end

  def render(template, _assigns) do
    %{
      error: %{
        type: "unknown_error",
        title: "Error",
        detail: Phoenix.Controller.status_message_from_template(template)
      }
    }
  end
end
