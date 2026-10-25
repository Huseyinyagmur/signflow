require "test_helper"
require "active_support/testing/constant_stubbing"
require_relative "../../script/support/signflow_agent"
require_relative "../support/gemini_transport"

class GeminiEndpointTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::ConstantStubbing

  class RecordingHttp
    Get = Net::HTTP::Get
    Post = Net::HTTP::Post
    HAVE_ZLIB = Net::HTTP::HAVE_ZLIB
    attr_accessor :use_ssl, :open_timeout, :read_timeout, :write_timeout, :max_retries
    attr_reader :host, :port, :proxy, :request_sent
    class << self
      attr_accessor :instances
    end

    def initialize(host, port, proxy)
      @host, @port, @proxy = host, port, proxy
      self.class.instances << self
    end

    def request(request)
      @request_sent = request
      body = if request.method == "GET"
        { name: "models/gemini-2.5-flash", supportedGenerationMethods: [ "generateContent" ] }
      else
        FakeGeminiTransport.function("get_template_version")
      end
      response = Struct.new(:code, :body) do
        def read_body = yield(body)
      end.new("200", JSON.generate(body))
      yield response
    end
  end

  test "actual HTTP builder uses HTTPS fixed Google host and correct Net HTTP methods without a real socket" do
    RecordingHttp.instances = []
    stub_const(Net, :HTTP, RecordingHttp) do
      provider = SignflowAgent::GeminiProvider.new(api_key: "synthetic-private-key", model: "gemini-2.5-flash", free_tier_confirmed: true)
      provider.verify_model!
      provider.reply(messages: [ { "role" => "user", "content" => "Synthetic" } ], tools: [])
    end
    assert_equal [ "GET", "POST" ], RecordingHttp.instances.map { |http| http.request_sent.method }
    assert_equal [ "/v1beta/models/gemini-2.5-flash", "/v1beta/models/gemini-2.5-flash:generateContent" ], RecordingHttp.instances.map { |http| http.request_sent.path }
    RecordingHttp.instances.each do |http|
      assert_equal "generativelanguage.googleapis.com", http.host
      assert_equal 443, http.port
      assert_nil http.proxy
      assert http.use_ssl
      assert_equal "synthetic-private-key", http.request_sent["x-goog-api-key"]
    end
  end

  test "configured model maps to exact v1beta GET metadata and POST generateContent paths" do
    config = SignflowAgent::ProviderConfig.new(env: { "SIGNFLOW_LLM_PROVIDER" => "gemini", "SIGNFLOW_LLM_MODEL" => "gemini-2.5-flash" })
    wire = FakeGeminiTransport.new(responses: [ FakeGeminiTransport.function("get_template_version") ])
    provider = SignflowAgent::GeminiProvider.new(api_key: "synthetic-private-key", model: config.model,
      free_tier_confirmed: true, transport: wire)
    assert_equal "gemini-2.5-flash", provider.model
    provider.verify_model!
    provider.reply(messages: [ { "role" => "user", "content" => "Synthetic" } ], tools: [])
    assert_equal [ [ :get, "/v1beta/models/gemini-2.5-flash" ], [ :post, "/v1beta/models/gemini-2.5-flash:generateContent" ] ],
      wire.requests.map { |method, path, *| [ method, path ] }
    assert_nil wire.requests.first[3]
    assert_kind_of Hash, JSON.parse(wire.requests.last[3])
    wire.requests.each do |_, path, headers, body|
      assert_equal "synthetic-private-key", headers["x-goog-api-key"]
      assert_not_includes path, "key="
      assert_not_includes body.to_s, "synthetic-private-key"
    end
  end

  test "404 on metadata never generates retries or falls back to another model" do
    calls = []
    wire = ->(method, path, *) { calls << [ method, path ]; [ 404, '{"error":{"message":"synthetic-private-key"}}' ] }
    provider = SignflowAgent::GeminiProvider.new(api_key: "synthetic-private-key", model: "gemini-2.5-flash", free_tier_confirmed: true, transport: wire)
    assert_equal "gemini_http_404", assert_raises(SignflowAgent::Error) { provider.verify_model! }.message
    assert_equal "model_access_not_verified", assert_raises(SignflowAgent::Error) { provider.reply(messages: [], tools: []) }.message
    assert_equal [ [ :get, "/v1beta/models/gemini-2.5-flash" ] ], calls
    assert_equal 0, provider.message_attempts
  end

  test "404 on generation after successful metadata stays an error with no retry or fallback" do
    wire = FakeGeminiTransport.new(responses: [ [ 404, '{"error":{"message":"synthetic-private-key"}}' ] ])
    provider = SignflowAgent::GeminiProvider.new(api_key: "synthetic-private-key", model: "gemini-2.5-flash", free_tier_confirmed: true, transport: wire)
    provider.verify_model!
    error = assert_raises(SignflowAgent::Error) { provider.reply(messages: [ { "role" => "user", "content" => "Synthetic" } ], tools: []) }
    assert_equal "gemini_http_404", error.message
    assert_equal 1, provider.message_attempts
    assert_equal 2, wire.requests.size
    assert_not_includes error.message, "synthetic-private-key"
  end
end
