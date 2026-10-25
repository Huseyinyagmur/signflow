require "test_helper"
require_relative "../../script/support/signflow_agent"

class AnthropicProviderTest < ActiveSupport::TestCase
  test "refuses paid calls without explicit authorization" do
    assert_raises(SignflowAgent::Error) do
      SignflowAgent::AnthropicProvider.new(api_key: "fake-provider-key", paid_allowed: false)
    end
  end

  test "verifies account model access and sends real messages wire format without API secret in context" do
    requests = []
    transport = ->(method, path, headers, body) do
      requests << [ method, path, headers, body ]
      if method == :get
        [ 200, JSON.generate(id: SignflowAgent::AnthropicProvider::DEFAULT_MODEL) ]
      else
        [ 200, JSON.generate(model: SignflowAgent::AnthropicProvider::DEFAULT_MODEL,
          content: [ { type: "text", citations: nil, text: '{"type":"question","fields":["recipient_email"]}' } ],
          stop_reason: "end_turn", usage: { input_tokens: 11, output_tokens: 7 }) ]
      end
    end
    provider = SignflowAgent::AnthropicProvider.new(api_key: "fake-provider-key", paid_allowed: true, transport: transport)
    provider.verify_model!
    response = provider.reply(messages: [ { "role" => "user", "content" => "Synthetic request" } ], tools: [])
    assert_equal 11, response.fetch("usage").fetch("input_tokens")
    assert_equal 1, provider.message_attempts
    assert_equal "fake-provider-key", requests.last[2].fetch("x-api-key")
    refute_includes requests.last[3], "fake-provider-key"
    assert_equal 1024, JSON.parse(requests.last[3]).fetch("max_tokens")
    assert_equal "/v1/messages", requests.last[1]
  end

  test "never falls back on unavailable model and sanitizes provider errors" do
    [ 401, 404, 429, 500 ].each do |status|
      attempts = 0
      transport = ->(*) { attempts += 1; [ status, '{"error":"fake-provider-key private error"}' ] }
      provider = SignflowAgent::AnthropicProvider.new(api_key: "fake-provider-key", paid_allowed: true, transport: transport, sleeper: ->(_) { })
      error = assert_raises(SignflowAgent::Error) { provider.verify_model! }
      refute_includes error.message, "fake-provider-key"
      assert_equal [ 429, 500 ].include?(status) ? 2 : 1, attempts
    end
  end

  test "timeouts are bounded and invalid provider JSON is rejected" do
    count = 0
    provider = SignflowAgent::AnthropicProvider.new(api_key: "fake", paid_allowed: true,
      transport: ->(*) { count += 1; raise Net::ReadTimeout }, sleeper: ->(_) { })
    assert_raises(SignflowAgent::Error) { provider.verify_model! }
    assert_equal 2, count
    provider = SignflowAgent::AnthropicProvider.new(api_key: "fake", paid_allowed: true, transport: ->(*) { [ 200, "not json" ] })
    assert_raises(SignflowAgent::Error) { provider.verify_model! }
  end
end
