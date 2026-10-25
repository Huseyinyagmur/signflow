require_relative "ai_contracts_test"
require_relative "../support/gemini_transport"

# All owner/CSRF/approval/signing assertions run again through actual Gemini
# functionCall/functionResponse conversion, with no network and no real key.
class GeminiWebContractsTest < AiContractsTest
  private

  def with_provider(responses)
    wire_responses = responses.map do |response|
      parts = response.fetch("content").map do |block|
        if block["type"] == "tool_use"
          { "functionCall" => { "name" => block["name"], "args" => block["input"] }, "thoughtSignature" => "test-opaque-signature" }
        else
          { "text" => block.fetch("text") }
        end
      end
      FakeGeminiTransport.response(parts)
    end
    wire_responses = [ [ 429, "{}" ], [ 429, "{}" ] ] if wire_responses.empty?
    wire = FakeGeminiTransport.new(responses: wire_responses)
    factory = Class.new do
      define_singleton_method(:build) do
        provider = SignflowAgent::GeminiProvider.new(api_key: "private-test-key", model: "gemini-2.5-flash",
          free_tier_confirmed: true, transport: wire, sleeper: ->(_) { })
        [ provider, [ "private-test-key" ] ]
      end
    end
    stub_const(AiContracts, :ProviderFactory, factory) { yield }
  end
end
