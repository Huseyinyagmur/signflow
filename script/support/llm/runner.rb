module SignflowAgent
  class Runner
    attr_reader :model_calls, :usage

    def initialize(provider:, tools:)
      @provider, @tools = provider, tools
      @model_calls, @usage = 0, { "input_tokens" => 0, "output_tokens" => 0 }
      @messages, @tool_count, @questions = [], 0, 0
    end

    def run(input:, ask:, confirm:)
      result = advance(input: input)
      loop do
        case result[:kind]
        when :question
          result = advance(input: ask.call(result[:fields]))
        when :proposal
          raise Error, "field_confirmation_declined" unless confirm.call(result[:payload])

          result = confirm_proposal!
        when :verified
          return result[:document]
        end
      end
    end

    # Pauses at the trust boundary. Web callers never invoke confirm_proposal!;
    # their separate authenticated POST commits through the document service.
    def advance(input:)
      raise Error, "proposal_already_pending" if @proposal

      @tools.add_user_text(input)
      @messages << { "role" => "user", "content" => input }
      pump
    end

    def confirm_proposal!
      raise Error, "no_proposal" unless @proposal

      @results << tool_result(@pending_call, @tools.create(@proposal))
      @proposal = nil
      process_calls || pump
    end

    private

    def pump
      while @model_calls < 8
        @model_calls += 1
        response = @provider.reply(messages: @messages, tools: @tools.definitions)
        @tools.check_content!(response)
        validate_reply!(response)
        add_usage(response["usage"])
        content = response.fetch("content")
        @messages << { "role" => "assistant", "content" => content }
        calls = content.select { |block| block["type"] == "tool_use" }
        if calls.any?
          raise Error, "invalid_model_stop" unless response["stop_reason"] == "tool_use"

          @calls, @results = calls, []
          result = process_calls
          return result if result
        else
          raise Error, "invalid_model_stop" unless response["stop_reason"] == "end_turn" && content.all? { |block| block["type"] == "text" }

          text = content.map { |block| block.fetch("text") }.join.strip
          text = text.sub(/\A```(?:json)?\s*\n/, "").sub(/\n```\z/, "")
          begin
            question = JSON.parse(text)
          rescue JSON::ParserError
            raise Error, "invalid_model_question_json" if @format_repaired

            @format_repaired = true
            @messages << { "role" => "user", "content" => 'Return only JSON {"type":"question","fields":[allowed missing field names]}. No prose or invented values.' }
            next
          end
          SignflowAgent.object!(question, keys: %w[type fields])
          raise Error, "invalid_question" unless question["type"] == "question" && @questions < 3

          fields = @tools.question_fields!(question["fields"])
          @questions += 1
          return { kind: :question, fields: fields }
        end
      end
      raise Error, "model_call_limit"
    rescue JSON::ParserError, KeyError, TypeError
      raise Error, "invalid_model_response"
    end

    def process_calls
      while (call = @calls.shift)
        @tool_count += 1
        raise Error, "tool_limit" if @tool_count > 10

        if call["name"] == "create_draft"
          @pending_call = call
          @proposal = @tools.prepare(call.fetch("input"))
          return { kind: :proposal, payload: @proposal }
        end
        @results << tool_result(call, @tools.call(call.fetch("name"), call.fetch("input")))
      end
      return { kind: :verified, document: @tools.verified } if @tools.verified

      @messages << { "role" => "user", "content" => @results }
      nil
    end

    def tool_result(call, result)
      { "type" => "tool_result", "tool_use_id" => call.fetch("id"), "content" => JSON.generate(result) }
    end

    def validate_reply!(response)
      raise Error, "invalid_model_response" unless response.is_a?(Hash) && response["content"].is_a?(Array) && response["content"].size.between?(1, 3)

      ids = []
      response["content"].each do |block|
        raise Error, "invalid_model_response" unless block.is_a?(Hash)

        if block["type"] == "tool_use"
          SignflowAgent.object!(block, keys: %w[type id name input])
          raise Error, "unknown_tool" unless %w[get_template_version create_draft get_draft].include?(block["name"])
          raise Error, "invalid_model_response" unless block["id"].is_a?(String) && block["id"].match?(/\A[a-zA-Z0-9_-]{1,128}\z/) && !ids.include?(block["id"]) && block["input"].is_a?(Hash)

          ids << block["id"]
        elsif block["type"] == "text"
          SignflowAgent.object!(block, keys: %w[type text])
          raise Error, "invalid_model_response" unless block["text"].is_a?(String) && block["text"].bytesize <= 10_000
        else
          raise Error, "invalid_model_response"
        end
      end
    end

    def add_usage(usage)
      return unless usage

      %w[input_tokens output_tokens].each do |key|
        value = usage[key]
        raise Error, "invalid_usage" unless value.is_a?(Integer) && value >= 0

        @usage[key] += value
      end
    end
  end
end
