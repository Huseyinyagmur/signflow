module SignflowAgent
  class GeminiProvider
    class Retryable < StandardError; end
    TOOL_NAMES = %w[get_template_version create_draft get_draft].freeze
    # Public-document review only; this is NOT an account/billing guarantee.
    FREE_REVIEWED_MODELS = %w[gemini-2.5-flash gemini-2.5-flash-lite gemini-3.5-flash-lite].freeze
    attr_reader :model, :message_attempts, :tier, :model_version

    def initialize(api_key:, model:, tier: "free", free_tier_confirmed: false, paid_allowed: false,
      transport: nil, sleeper: ->(seconds) { sleep(seconds) })
      self.class.check_consent!(model: model, tier: tier, free_tier_confirmed: free_tier_confirmed, paid_allowed: paid_allowed)
      raise Error, "gemini_key_required" if api_key.to_s.empty?

      @api_key, @model, @tier, @transport, @sleeper = api_key, model, tier, transport, sleeper
      @message_attempts, @turns, @calls = 0, [], {}
    end

    def self.check_consent!(model:, tier:, free_tier_confirmed:, paid_allowed:)
      raise Error, "gemini_model_required" unless model.is_a?(String) && model.match?(/\Agemini-[a-z0-9.-]{1,100}\z/)
      raise Error, "invalid_gemini_tier" unless %w[free paid].include?(tier)
      if tier == "free"
        raise Error, "gemini_free_tier_confirmation_required" unless free_tier_confirmed
        raise Error, "gemini_model_free_tier_not_reviewed" unless FREE_REVIEWED_MODELS.include?(model)
      else
        raise Error, "paid_calls_not_authorized" unless paid_allowed
      end
    end

    def verify_model!
      result = request(:get, "/v1beta/models/#{@model}")
      raise Error, "gemini_model_unavailable" unless result.is_a?(Hash) && result["name"] == "models/#{@model}" &&
        result["supportedGenerationMethods"].is_a?(Array) && result["supportedGenerationMethods"].include?("generateContent")

      @verified = true
    end

    def reply(messages:, tools:)
      raise Error, "model_access_not_verified" unless @verified
      raise Error, "model_context_limit" unless messages.is_a?(Array) && messages.size <= 30 && JSON.generate(messages).bytesize <= 64_000

      declarations = tools.map do |tool|
        tool = JSON.parse(JSON.generate(tool))
        raise Error, "unknown_tool" unless TOOL_NAMES.include?(tool["name"])
        { "name" => tool.fetch("name"), "description" => tool.fetch("description"), "parametersJsonSchema" => tool.fetch("input_schema") }
      end
      contents = to_contents(messages)
      config = { "maxOutputTokens" => 2048, "candidateCount" => 1 }
      config["thinkingConfig"] = { "thinkingBudget" => 0 } if @model.start_with?("gemini-2.5-")
      body = { "systemInstruction" => { "parts" => [ { "text" => Policy::SYSTEM } ] }, "contents" => contents,
        "generationConfig" => config, "tools" => [ { "functionDeclarations" => declarations } ] }
      result = request(:post, "/v1beta/models/#{@model}:generateContent", body)
      decode(result)
    rescue KeyError, TypeError, JSON::ParserError
      raise Error, "invalid_gemini_response"
    end

    private

    def to_contents(messages)
      turn = 0
      contents = messages.map do |message|
        if message["role"] == "assistant"
          cached = @turns[turn]
          raise Error, "gemini_history_mismatch" unless cached && cached[:normalized] == message["content"]

          turn += 1
          cached.fetch(:raw)
        elsif message["role"] == "user"
          content = message["content"]
          parts = if content.is_a?(String)
            [ { "text" => content } ]
          elsif content.is_a?(Array)
            content.map do |block|
              SignflowAgent.object!(block, keys: %w[type tool_use_id content])
              call = @calls[block["tool_use_id"]]
              raise Error, "gemini_unknown_tool_result" unless block["type"] == "tool_result" && call

              result = JSON.parse(block.fetch("content"))
              raise Error, "invalid_tool_result" unless result.is_a?(Hash)

              response = { "name" => call.fetch(:name), "response" => result }
              response["id"] = call[:wire_id] if call[:wire_id]
              { "functionResponse" => response }
            end
          else
            raise Error, "invalid_gemini_history"
          end
          { "role" => "user", "parts" => parts }
        else
          raise Error, "invalid_gemini_history"
        end
      end
      raise Error, "gemini_history_mismatch" unless turn == @turns.size

      contents
    end

    def decode(result)
      raise Error, "invalid_gemini_response" unless result.is_a?(Hash)
      raise Error, "gemini_prompt_blocked" if result.dig("promptFeedback", "blockReason")

      candidates = result["candidates"]
      raise Error, "invalid_gemini_response" unless candidates.is_a?(Array) && candidates.size == 1

      candidate = candidates.first
      raise Error, "gemini_generation_incomplete" unless candidate.is_a?(Hash) && candidate["finishReason"] == "STOP"

      raw = candidate.fetch("content")
      SignflowAgent.object!(raw, keys: %w[role parts])
      raise Error, "invalid_gemini_response" unless raw.is_a?(Hash) && raw["role"] == "model" && raw["parts"].is_a?(Array) && raw["parts"].size.between?(1, 6)

      normalized = []
      raw["parts"].each do |part|
        SignflowAgent.object!(part, keys: %w[text functionCall thoughtSignature thought], required: [])
        raise Error, "unexpected_gemini_thought" if part["thought"] == true
        if part.key?("thoughtSignature")
          raise Error, "invalid_gemini_signature" unless part["thoughtSignature"].is_a?(String) && part["thoughtSignature"].bytesize.between?(1, 100_000)
        end
        raise Error, "invalid_gemini_part" if part.key?("text") && part.key?("functionCall")

        if part.key?("functionCall")
          call = part.fetch("functionCall")
          SignflowAgent.object!(call, keys: %w[name args id], required: %w[name])
          raise Error, "unknown_tool" unless TOOL_NAMES.include?(call["name"])
          args = call["args"]
          args = {} if !call.key?("args") && %w[get_template_version get_draft].include?(call["name"])
          raise Error, "invalid_gemini_arguments" unless args.is_a?(Hash)
          raise Error, "invalid_gemini_call_id" if call.key?("id") && (!call["id"].is_a?(String) || call["id"].size > 256)

          id = "gemini_#{SecureRandom.hex(12)}"
          @calls[id] = { name: call["name"], wire_id: call["id"] }
          normalized << { "type" => "tool_use", "id" => id, "name" => call["name"], "input" => args }
        elsif part.key?("text")
          raise Error, "invalid_gemini_text" unless part["text"].is_a?(String) && part["text"].bytesize <= 10_000

          normalized << { "type" => "text", "text" => part["text"] } unless part["text"].empty?
        elsif !part.key?("thoughtSignature")
          raise Error, "invalid_gemini_part"
        end
      end
      raise Error, "invalid_gemini_response" unless normalized.size.between?(1, 3)

      usage = result.fetch("usageMetadata")
      raise Error, "invalid_gemini_usage" unless usage.is_a?(Hash)
      counts = %w[promptTokenCount candidatesTokenCount thoughtsTokenCount].map do |key|
        value = usage.fetch(key, 0)
        raise Error, "invalid_gemini_usage" unless value.is_a?(Integer) && value >= 0

        value
      end
      version = result["modelVersion"]
      if version
        raise Error, "gemini_model_mismatch" unless version.is_a?(String) && (version == @model || version.start_with?("#{@model}-"))

        @model_version = version
      end
      @turns << { raw: JSON.parse(JSON.generate(raw)), normalized: JSON.parse(JSON.generate(normalized)) }
      { "content" => normalized, "stop_reason" => normalized.any? { |block| block["type"] == "tool_use" } ? "tool_use" : "end_turn",
        "usage" => { "input_tokens" => counts[0], "output_tokens" => counts[1] + counts[2] } }
    end

    def request(method, path, body = nil)
      headers = { "x-goog-api-key" => @api_key, "content-type" => "application/json" }
      attempts = 0
      begin
        attempts += 1
        @message_attempts += 1 if method == :post
        status, raw = @transport ? @transport.call(method, path, headers, body && JSON.generate(body)) : http_request(method, path, headers, body)
        raise Retryable if [ 429, 500, 502, 503, 504 ].include?(status) && attempts < 2
        raise Error, "gemini_http_#{Integer(status)}" unless status == 200
        raise Error, "invalid_gemini_response" unless raw.is_a?(String) && raw.bytesize <= 1_000_000

        JSON.parse(raw)
      rescue Retryable, IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
        if attempts < 2
          @sleeper.call(0.5)
          retry
        end
        raise Error, "gemini_transport_error"
      rescue JSON::ParserError, ArgumentError, TypeError
        raise Error, "invalid_gemini_response"
      end
    end

    def http_request(method, path, headers, body)
      request = (method == :post ? Net::HTTP::Post : Net::HTTP::Get).new(path, headers)
      request.body = JSON.generate(body) if body
      http = Net::HTTP.new("generativelanguage.googleapis.com", 443, nil)
      http.use_ssl = true
      http.open_timeout, http.read_timeout, http.write_timeout = 5, 30, 10
      http.max_retries = 0
      raw, status = +"", nil
      http.request(request) do |response|
        status = response.code.to_i
        response.read_body do |chunk|
          raise Error, "gemini_response_too_large" if raw.bytesize + chunk.bytesize > 1_000_000

          raw << chunk
        end
      end
      [ status, raw ]
    end
  end
end
