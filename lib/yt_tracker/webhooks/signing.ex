defmodule YtTracker.Webhooks.Signing do
  @moduledoc """
  Utilities for signing and verifying webhook payloads.
  """

  import Bitwise

  @doc """
  Signs a payload with HMAC-SHA256.
  Returns the hex-encoded signature.
  """
  def sign_payload(payload, secret) when is_binary(payload) and is_binary(secret) do
    :crypto.mac(:hmac, :sha256, secret, payload)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies a webhook signature.
  """
  def verify_signature(payload, signature, secret) do
    expected_signature = sign_payload(payload, secret)
    secure_compare(signature, expected_signature)
  end

  @doc """
  Constant-time string comparison to prevent timing attacks.
  """
  def secure_compare(a, b) when is_binary(a) and is_binary(b) do
    if byte_size(a) == byte_size(b) do
      secure_compare(a, b, 0) == 0
    else
      false
    end
  end

  defp secure_compare(<<a, rest_a::binary>>, <<b, rest_b::binary>>, acc) do
    secure_compare(rest_a, rest_b, acc ||| bxor(a, b))
  end

  defp secure_compare(<<>>, <<>>, acc), do: acc
end
