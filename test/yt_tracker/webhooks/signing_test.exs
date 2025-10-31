defmodule YtTracker.Webhooks.SigningTest do
  use ExUnit.Case, async: true

  alias YtTracker.Webhooks.Signing

  describe "sign_payload/2" do
    test "generates consistent signatures" do
      payload = ~s({"event": "test"})
      secret = "test_secret"

      sig1 = Signing.sign_payload(payload, secret)
      sig2 = Signing.sign_payload(payload, secret)

      assert sig1 == sig2
      assert is_binary(sig1)
    end

    test "different payloads produce different signatures" do
      secret = "test_secret"

      sig1 = Signing.sign_payload("payload1", secret)
      sig2 = Signing.sign_payload("payload2", secret)

      assert sig1 != sig2
    end

    test "different secrets produce different signatures" do
      payload = "test payload"

      sig1 = Signing.sign_payload(payload, "secret1")
      sig2 = Signing.sign_payload(payload, "secret2")

      assert sig1 != sig2
    end
  end

  describe "verify_signature/3" do
    test "verifies valid signature" do
      payload = ~s({"event": "test"})
      secret = "test_secret"
      signature = Signing.sign_payload(payload, secret)

      assert Signing.verify_signature(payload, signature, secret)
    end

    test "rejects invalid signature" do
      payload = ~s({"event": "test"})
      secret = "test_secret"

      refute Signing.verify_signature(payload, "invalid_signature", secret)
    end

    test "rejects signature with wrong secret" do
      payload = ~s({"event": "test"})
      signature = Signing.sign_payload(payload, "secret1")

      refute Signing.verify_signature(payload, signature, "secret2")
    end
  end

  describe "secure_compare/2" do
    test "returns true for identical strings" do
      assert Signing.secure_compare("test", "test")
    end

    test "returns false for different strings" do
      refute Signing.secure_compare("test1", "test2")
    end

    test "returns false for strings of different lengths" do
      refute Signing.secure_compare("test", "testing")
    end
  end
end
