require "test_helper"

class AiProviderFactoryTest < ActiveSupport::TestCase
  test "web backend fails closed before any network or key access without consent" do
    env = { "SIGNFLOW_LLM_PROVIDER" => "gemini", "SIGNFLOW_LLM_MODEL" => "gemini-2.5-flash" }
    assert_equal "synthetic_data_required", assert_raises(SignflowAgent::Error) { AiContracts::ProviderFactory.build(env: env) }.message
    env["SIGNFLOW_SYNTHETIC_DATA"] = "true"
    assert_equal "gemini_free_tier_confirmation_required", assert_raises(SignflowAgent::Error) { AiContracts::ProviderFactory.build(env: env) }.message
    env["SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED"] = "true"
    assert_equal "gemini_key_required", assert_raises(SignflowAgent::Error) { AiContracts::ProviderFactory.build(env: env) }.message
    env["GEMINI_API_KEY"] = "synthetic-key-not-real"
    provider, secrets = AiContracts::ProviderFactory.build(env: env)
    assert_instance_of SignflowAgent::GeminiProvider, provider
    assert_equal [ "synthetic-key-not-real" ], secrets
    assert_equal 0, provider.message_attempts
    env["SIGNFLOW_GEMINI_TIER"] = "paid"
    assert_equal "paid_calls_not_authorized", assert_raises(SignflowAgent::Error) { AiContracts::ProviderFactory.build(env: env) }.message
  end
end
