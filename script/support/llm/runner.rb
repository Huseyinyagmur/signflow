module SignflowAgent
  class Runner
    attr_reader :model_calls, :usage

    def initialize(provider:, tools:)
      @provider, @tools = provider, tools
      @model_calls, @usage = 0, { "input_tokens" => 0, "output_tokens" => 0 }
    end

    def run(input:, ask:, confirm:)
      @tools.add_user_text(input)
      messages = [ { "role" => "user", "content" => input } ]
      tool_count, questions = 0, 0
      8.times do
        @model_calls += 1
        response = @provider.reply(messages: messages, tools: @tools.definitions)
        @tools.check_content!(response)
        validate_reply!(response)
        add_usage(response["usage"])
        content = response.fetch("content")
        messages << { "role" => "assistant", "content" => content }
        calls = content.select { |block| block["type"] == "tool_use" }
        if calls.any?
          raise Error, "invalid_model_stop" unless response["stop_reason"] == "tool_use"

          results = calls.map do |call|
            tool_count += 1
            raise Error, "tool_limit" if tool_count > 10

            result = if call["name"] == "create_draft"
              payload = @tools.prepare(call.fetch("input"))
              raise Error, "field_confirmation_declined" unless confirm.call(payload)

              @tools.create(payload)
            else
              @tools.call(call.fetch("name"), call.fetch("input"))
            end
            { "type" => "tool_result", "tool_use_id" => call.fetch("id"), "content" => JSON.generate(result) }
          end
          return @tools.verified if @tools.verified

          messages << { "role" => "user", "content" => results }
        else
          raise Error, "invalid_model_stop" unless response["stop_reason"] == "end_turn" && content.size == 1 && content.first["type"] == "text"

          question = JSON.parse(content.first.fetch("text"))
          SignflowAgent.object!(question, keys: %w[type fields])
          raise Error, "invalid_question" unless question["type"] == "question" && questions < 3

          fields = @tools.question_fields!(question["fields"])
          answer = ask.call(fields)
          @tools.add_user_text(answer)
          questions += 1
          messages << { "role" => "user", "content" => answer }
        end
      end
      raise Error, "model_call_limit"
    rescue JSON::ParserError, KeyError, TypeError
      raise Error, "invalid_model_response"
    end

    private

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
