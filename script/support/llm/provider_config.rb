module SignflowAgent
  class ProviderConfig
    attr_reader :name, :model, :tier

    def initialize(env: ENV)
      @env = env
      @name = env.fetch("SIGNFLOW_LLM_PROVIDER", "anthropic")
      raise Error, "unknown_llm_provider" unless %w[anthropic gemini].include?(@name)

      @model = env.fetch("SIGNFLOW_LLM_MODEL", @name == "anthropic" ? AnthropicProvider::DEFAULT_MODEL : "")
      @tier = @name == "gemini" ? env.fetch("SIGNFLOW_GEMINI_TIER", "free") : "paid"
    end

    def check_consent!
      if @name == "anthropic"
        raise Error, "paid_calls_not_authorized" unless @env["SIGNFLOW_ALLOW_PAID_LLM"] == "true"
      else
        GeminiProvider.check_consent!(model: @model, tier: @tier,
          free_tier_confirmed: @env["SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED"] == "true", paid_allowed: @env["SIGNFLOW_ALLOW_PAID_LLM"] == "true")
      end
    end

    def secret_name
      @name == "gemini" ? "GEMINI_API_KEY" : "ANTHROPIC_API_KEY"
    end

    def build(api_key:)
      check_consent!
      if @name == "gemini"
        GeminiProvider.new(api_key: api_key, model: @model, tier: @tier,
          free_tier_confirmed: @env["SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED"] == "true", paid_allowed: @env["SIGNFLOW_ALLOW_PAID_LLM"] == "true")
      else
        AnthropicProvider.new(api_key: api_key, model: @model, paid_allowed: true)
      end
    end
  end
end
