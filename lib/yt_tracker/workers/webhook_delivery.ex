defmodule YtTracker.Workers.WebhookDelivery do
  @moduledoc """
  Delivers webhooks to registered endpoints with retry logic.
  """

  use Oban.Worker,
    queue: :webhooks,
    max_attempts: 5

  alias YtTracker.{Repo, Webhooks}
  alias YtTracker.Webhooks.Delivery

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"delivery_id" => delivery_id}, attempt: attempt}) do
    delivery = Repo.get!(Delivery, delivery_id) |> Repo.preload(:endpoint)

    Logger.info("Delivering webhook #{delivery.id} (attempt #{attempt})")

    case deliver_webhook(delivery) do
      {:ok, response} ->
        mark_delivered(delivery, response)
        {:ok, response}

      {:error, reason} ->
        handle_delivery_failure(delivery, reason, attempt)
    end
  end

  defp deliver_webhook(delivery) do
    endpoint = delivery.endpoint
    payload = Jason.encode!(delivery.payload)
    signature = Webhooks.Signing.sign_payload(payload, endpoint.secret)

    headers = [
      {"content-type", "application/json"},
      {"x-webhook-signature", "sha256=#{signature}"},
      {"x-webhook-event", delivery.event_type},
      {"x-webhook-id", delivery.id}
    ]

    case Req.post(endpoint.url, body: payload, headers: headers, retry: false) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, %{status: status, body: body}}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp mark_delivered(delivery, response) do
    now = DateTime.utc_now()

    delivery
    |> Delivery.changeset(%{
      status: "sent",
      response_status: response.status,
      response_body: inspect(response.body) |> String.slice(0, 1000),
      sent_at: now,
      attempt_count: delivery.attempt_count + 1
    })
    |> Repo.update()
  end

  defp handle_delivery_failure(delivery, reason, attempt) do
    max_attempts = delivery.max_attempts

    if attempt >= max_attempts do
      mark_failed(delivery, reason)
      {:discard, reason}
    else
      mark_retrying(delivery, reason, attempt)
      {:error, reason}
    end
  end

  defp mark_failed(delivery, reason) do
    delivery
    |> Delivery.changeset(%{
      status: "failed",
      error: inspect(reason) |> String.slice(0, 1000),
      attempt_count: delivery.attempt_count + 1
    })
    |> Repo.update()
  end

  defp mark_retrying(delivery, reason, attempt) do
    next_attempt_at = calculate_next_attempt(attempt)

    delivery
    |> Delivery.changeset(%{
      status: "retrying",
      error: inspect(reason) |> String.slice(0, 1000),
      attempt_count: delivery.attempt_count + 1,
      next_attempt_at: next_attempt_at
    })
    |> Repo.update()
  end

  defp calculate_next_attempt(attempt) do
    # Exponential backoff: 1m, 5m, 15m, 1h, 24h
    delay_seconds =
      case attempt do
        1 -> 60
        2 -> 300
        3 -> 900
        4 -> 3600
        _ -> 86400
      end

    DateTime.add(DateTime.utc_now(), delay_seconds, :second)
  end
end
