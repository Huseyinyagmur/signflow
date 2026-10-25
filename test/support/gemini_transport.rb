class FakeGeminiTransport
  attr_reader :requests

  def initialize(responses:, model: "gemini-2.5-flash")
    @responses, @model, @requests = responses, model, []
  end

  def call(method, path, headers, body)
    @requests << [ method, path, headers, body ]
    return [ 200, JSON.generate(name: "models/#{@model}", supportedGenerationMethods: [ "generateContent" ]) ] if method == :get

    response = @responses.shift || raise("Unexpected generation")
    raise response if response.is_a?(Exception)
    return response if response.is_a?(Array)

    [ 200, JSON.generate(response) ]
  end

  def self.function(name, args = {}, signature: "opaque-test-signature")
    response([ { "functionCall" => { "name" => name, "args" => args }, "thoughtSignature" => signature } ])
  end

  def self.response(parts, finish: "STOP")
    { "candidates" => [ { "content" => { "role" => "model", "parts" => parts }, "finishReason" => finish } ],
      "usageMetadata" => { "promptTokenCount" => 11, "candidatesTokenCount" => 7, "thoughtsTokenCount" => 2 }, "modelVersion" => "gemini-2.5-flash" }
  end
end
