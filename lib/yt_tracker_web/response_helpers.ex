defmodule YtTrackerWeb.ResponseHelpers do
  @moduledoc """
  Helpers for building consistent API responses.
  """

  import Plug.Conn

  @doc """
  Renders a success response with data envelope.
  """
  def render_success(conn, data, opts \\ []) do
    response = %{data: data}

    response =
      if meta = Keyword.get(opts, :meta) do
        Map.put(response, :meta, meta)
      else
        response
      end

    response =
      if links = Keyword.get(opts, :links) do
        Map.put(response, :links, links)
      else
        response
      end

    conn
    |> put_status(Keyword.get(opts, :status, :ok))
    |> Phoenix.Controller.json(response)
  end

  @doc """
  Renders an error response following RFC 7807.
  """
  def render_error(conn, type, title, detail, opts \\ []) do
    status = Keyword.get(opts, :status, :bad_request)

    error = %{
      type: type,
      title: title,
      detail: detail,
      status: Plug.Conn.Status.code(status)
    }

    conn
    |> put_status(status)
    |> Phoenix.Controller.json(%{error: error})
  end

  @doc """
  Renders a changeset error.
  """
  def render_changeset_error(conn, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    render_error(conn, "validation_error", "Validation Error", "Invalid input parameters",
      status: :unprocessable_entity
    )
    |> Map.put(:errors, errors)
  end
end
