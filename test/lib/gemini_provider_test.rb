require "test_helper"
require "tmpdir"
require_relative "../../script/support/signflow_agent"
require_relative "../support/gemini_transport"

class GeminiProviderTest < ActiveSupport::TestCase
  test "free and paid modes require distinct explicit consent and model selection" do
    assert_raises(SignflowAgent::Error) { provider(transport: nil, free_tier_confirmed: false) }
    assert_raises(SignflowAgent::Error) { provider(transport: nil, tier: "paid", paid_allowed: false) }
    assert_raises(SignflowAgent::Error) { provider(transport: nil, model: "gemini-unreviewed") }
    assert_raises(SignflowAgent::Error) { provider(transport: nil, model: "../unsafe") }
    assert_raises(SignflowAgent::Error) { provider(transport: nil, model: "") }
    assert_instance_of SignflowAgent::GeminiProvider, provider(transport: nil, tier: "paid", paid_allowed: true)
  end

  test "REST declarations calls responses and opaque signatures round trip without secrets" do
    wire = FakeGeminiTransport.new(responses: [ FakeGeminiTransport.function("get_template_version"),
      FakeGeminiTransport.response([ { "text" => '{"type":"question","fields":["recipient_email"]}' } ]) ])
    client = provider(transport: wire)
    client.verify_model!
    tools = [ { name: "get_template_version", description: "Read manifest", input_schema: { type: "object", properties: {}, additionalProperties: false } } ]
    messages = [ { "role" => "user", "content" => "Synthetic input" } ]
    first = client.reply(messages: messages, tools: tools)
    call = first.fetch("content").first
    assert_equal "tool_use", call["type"]
    assert_equal "get_template_version", call["name"]
    refute_includes JSON.generate(first), "opaque-test-signature"
    messages << { "role" => "assistant", "content" => first.fetch("content") }
    messages << { "role" => "user", "content" => [ { "type" => "tool_result", "tool_use_id" => call.fetch("id"), "content" => JSON.generate(id: 2, variables: []) } ] }
    second = client.reply(messages: messages, tools: tools)
    assert_equal "end_turn", second["stop_reason"]
    assert_equal 9, second["usage"]["output_tokens"]
    request = wire.requests.last
    assert_equal "/v1beta/models/gemini-2.5-flash:generateContent", request[1]
    assert_equal "fake-gemini-key", request[2]["x-goog-api-key"]
    refute_includes request[1], "key="
    refute_includes request[3], "fake-gemini-key"
    body = JSON.parse(request[3])
    assert_equal "opaque-test-signature", body["contents"][1]["parts"][0]["thoughtSignature"]
    assert_equal "get_template_version", body["contents"][2]["parts"][0]["functionResponse"]["name"]
    assert_equal 2, body["contents"][2]["parts"][0]["functionResponse"]["response"]["id"]
    assert_equal false, body["tools"][0]["functionDeclarations"][0]["parametersJsonSchema"]["additionalProperties"]
    assert_equal 2, client.message_attempts
  end

  test "auth unavailable quota timeout and JSON failures are bounded and sanitized" do
    [ 401, 403, 404, 429, 500 ].each do |status|
      attempts = 0
      transport = ->(*) { attempts += 1; [ status, '{"error":"fake-gemini-key private"}' ] }
      error = assert_raises(SignflowAgent::Error) { provider(transport: transport).verify_model! }
      assert_equal [ 429, 500 ].include?(status) ? 2 : 1, attempts
      refute_includes error.message, "fake-gemini-key"
    end
    count = 0
    assert_raises(SignflowAgent::Error) do
      provider(transport: ->(*) { count += 1; raise Net::ReadTimeout }).verify_model!
    end
    assert_equal 2, count
    assert_raises(SignflowAgent::Error) { provider(transport: ->(*) { [ 200, "invalid JSON" ] }).verify_model! }
    assert_raises(SignflowAgent::Error) { provider(transport: ->(*) { [ 200, JSON.generate(name: "models/other", supportedGenerationMethods: []) ] }).verify_model! }
  end

  test "configured newer free candidate retains wire ids and detects altered history" do
    response = FakeGeminiTransport.function("get_template_version")
    response["modelVersion"] = "gemini-3.5-flash-lite"
    response["candidates"][0]["content"]["parts"][0]["functionCall"] = { "name" => "get_template_version", "id" => "wire-001" }
    wire = FakeGeminiTransport.new(model: "gemini-3.5-flash-lite", responses: [ response, response ])
    client = provider(transport: wire, model: "gemini-3.5-flash-lite")
    client.verify_model!
    messages = [ { "role" => "user", "content" => "Synthetic" } ]
    first = client.reply(messages: messages, tools: [])
    messages << { "role" => "assistant", "content" => first["content"] }
    messages << { "role" => "user", "content" => [ { "type" => "tool_result", "tool_use_id" => first["content"][0]["id"], "content" => "{}" } ] }
    client.reply(messages: messages, tools: [])
    body = JSON.parse(wire.requests.last[3])
    assert_equal "wire-001", body["contents"][2]["parts"][0]["functionResponse"]["id"]
    refute body["generationConfig"].key?("thinkingConfig")
    messages[1]["content"][0]["name"] = "send_for_signature"
    assert_raises(SignflowAgent::Error) { client.reply(messages: messages, tools: []) }
  end

  test "malformed blocked truncated and unknown tool results fail closed" do
    bad = [ {}, { "promptFeedback" => { "blockReason" => "SAFETY" } },
      FakeGeminiTransport.response([ { "text" => "partial" } ], finish: "MAX_TOKENS"),
      FakeGeminiTransport.function("send_for_signature"),
      FakeGeminiTransport.response([ { "executableCode" => { "code" => "secret" } } ]),
      FakeGeminiTransport.response([ { "functionCall" => { "name" => "get_draft", "args" => [] } } ]) ]
    bad.each do |response|
      client = provider(transport: FakeGeminiTransport.new(responses: [ response ]))
      client.verify_model!
      assert_raises(SignflowAgent::Error) { client.reply(messages: [ { "role" => "user", "content" => "Synthetic" } ], tools: []) }
    end
  end

  test "generation timeout retries the exact same request without another model turn" do
    wire = FakeGeminiTransport.new(responses: [ Net::ReadTimeout.new, FakeGeminiTransport.function("get_template_version") ])
    client = provider(transport: wire)
    client.verify_model!
    result = client.reply(messages: [ { "role" => "user", "content" => "Synthetic" } ], tools: [])
    assert_equal "tool_use", result["stop_reason"]
    assert_equal 2, client.message_attempts
    posts = wire.requests.select { |request| request.first == :post }
    assert_equal posts.first[3], posts.last[3]
  end

  test "Gemini drives missing information grounded creation and deterministic resume with no extra generation" do
    directory = Dir.mktmpdir("signflow-gemini-test")
    job = SignflowAgent::Job.new(directory: directory, id: "test", binding: { "base_url" => "https://example.com", "template_id" => 1, "version_id" => 2 })
    api = LocalApi.new
    candidate = { "values" => { "hizmet" => "yazılım" }, "document" => { "recipient_name" => "Ahmet", "recipient_email" => "ahmet@example.com", "expires_at" => "2030-01-01T18:00:00+03:00" } }
    wire = FakeGeminiTransport.new(responses: [ FakeGeminiTransport.function("get_template_version"),
      FakeGeminiTransport.response([ { "text" => '{"type":"question","fields":["recipient_email","expires_at"]}' } ]),
      FakeGeminiTransport.function("create_draft", candidate), FakeGeminiTransport.function("get_draft") ])
    client = provider(transport: wire)
    client.verify_model!
    tools = SignflowAgent::Tools.new(api: api, job: job, secrets: [ "fake-gemini-key" ])
    questions = []
    result = SignflowAgent::Runner.new(provider: client, tools: tools).run(input: "Ahmet için yazılım",
      ask: ->(fields) { questions << fields; "ahmet@example.com 2030-01-01T18:00:00+03:00" }, confirm: ->(_) { true })
    assert_equal 9, result["id"]
    assert_equal [ %w[recipient_email expires_at] ], questions
    assert_equal 4, client.message_attempts
    assert_equal 9, tools.resume["id"]
    assert_equal 4, client.message_attempts
    assert_equal 1, api.keys.uniq.size
    refute_includes File.read(job.path), "fake-gemini-key"
  ensure
    job&.close
    if directory
      raise "Unsafe test path" unless File.expand_path(directory).start_with?(File.expand_path(Dir.tmpdir) + File::SEPARATOR) && File.basename(directory).start_with?("signflow-gemini-test")
      FileUtils.remove_entry(directory)
    end
  end

  test "Gemini hallucinated values cannot cross the existing tool boundary" do
    directory = Dir.mktmpdir("signflow-gemini-test")
    job = SignflowAgent::Job.new(directory: directory, id: "test", binding: { "base_url" => "https://example.com", "template_id" => 1, "version_id" => 2 })
    api = LocalApi.new
    candidate = { "values" => { "hizmet" => "yazılım" }, "document" => { "recipient_name" => "Ahmet", "recipient_email" => "invented@example.com", "expires_at" => "2030-01-01T18:00:00+03:00" } }
    client = provider(transport: FakeGeminiTransport.new(responses: [ FakeGeminiTransport.function("get_template_version"), FakeGeminiTransport.function("create_draft", candidate) ]))
    client.verify_model!
    tools = SignflowAgent::Tools.new(api: api, job: job, secrets: [])
    assert_raises(SignflowAgent::Error) do
      SignflowAgent::Runner.new(provider: client, tools: tools).run(input: "Ahmet yazılım 2030-01-01T18:00:00+03:00", ask: ->(_) { "" }, confirm: ->(_) { flunk })
    end
    assert_empty api.keys
  ensure
    job&.close
    if directory
      raise "Unsafe test path" unless File.expand_path(directory).start_with?(File.expand_path(Dir.tmpdir) + File::SEPARATOR) && File.basename(directory).start_with?("signflow-gemini-test")
      FileUtils.remove_entry(directory)
    end
  end

  class LocalApi
    attr_reader :keys
    def initialize
      @keys = []
    end
    def request(method, path, **options)
      return { "id" => 2, "template_id" => 1, "number" => 1, "title" => "Demo", "variables" => [ "hizmet" ] } if path.include?("templates")
      result = { "id" => 9, "title" => "Demo", "content" => "Demo", "status" => "draft", "template_version_id" => 2, "review_path" => "/documents/9" }
      if method == :post
        @keys << options.fetch(:key)
        result["replayed"] = @keys.size > 1
      end
      result
    end
  end

  private
  def provider(transport:, **options)
    SignflowAgent::GeminiProvider.new(api_key: "fake-gemini-key", model: "gemini-2.5-flash", free_tier_confirmed: true,
      transport: transport, sleeper: ->(_) { }, **options)
  end
end
