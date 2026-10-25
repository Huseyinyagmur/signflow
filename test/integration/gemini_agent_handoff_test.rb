require_relative "llm_agent_handoff_test"
require_relative "../support/gemini_transport"

# Same real Rails API/CSRF/recipient assertions as Anthropic-neutral handoff,
# but wire responses are converted by the actual Gemini adapter.
class GeminiAgentHandoffTest < LlmAgentHandoffTest
  private

  def build_provider(candidate)
    wire = FakeGeminiTransport.new(responses: [ FakeGeminiTransport.function("get_template_version"),
      FakeGeminiTransport.function("create_draft", candidate), FakeGeminiTransport.function("get_draft") ])
    provider = SignflowAgent::GeminiProvider.new(api_key: "fake-gemini-key", model: "gemini-2.5-flash",
      free_tier_confirmed: true, transport: wire)
    provider.verify_model!
    provider
  end
end
