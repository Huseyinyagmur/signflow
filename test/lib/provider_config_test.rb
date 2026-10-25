require "test_helper"
require_relative "../../script/support/signflow_agent"

class ProviderConfigTest < ActiveSupport::TestCase
  test "Anthropic remains the default and requires paid authorization" do
    config = SignflowAgent::ProviderConfig.new(env: {})
    assert_equal "anthropic", config.name
    assert_equal "ANTHROPIC_API_KEY", config.secret_name
    assert_raises(SignflowAgent::Error) { config.check_consent! }
    config = SignflowAgent::ProviderConfig.new(env: { "SIGNFLOW_ALLOW_PAID_LLM" => "true" })
    assert_instance_of SignflowAgent::AnthropicProvider, config.build(api_key: "fake")
  end

  test "Gemini has no implicit model or silent fallback and free mode is not paid consent" do
    env = { "SIGNFLOW_LLM_PROVIDER" => "gemini", "SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED" => "true" }
    assert_raises(SignflowAgent::Error) { SignflowAgent::ProviderConfig.new(env: env).check_consent! }
    env["SIGNFLOW_LLM_MODEL"] = "gemini-3.5-flash-lite"
    config = SignflowAgent::ProviderConfig.new(env: env)
    assert_equal "GEMINI_API_KEY", config.secret_name
    assert_instance_of SignflowAgent::GeminiProvider, config.build(api_key: "fake")
    env["SIGNFLOW_GEMINI_TIER"] = "paid"
    assert_raises(SignflowAgent::Error) { SignflowAgent::ProviderConfig.new(env: env).check_consent! }
    assert_raises(SignflowAgent::Error) { SignflowAgent::ProviderConfig.new(env: { "SIGNFLOW_LLM_PROVIDER" => "unknown" }) }
  end

  test "Google API key shaped user text is rejected before entering model context" do
    assert_raises(SignflowAgent::Error) { SignflowAgent.reject_secrets!("AIza#{'x' * 35}", []) }
  end
end
