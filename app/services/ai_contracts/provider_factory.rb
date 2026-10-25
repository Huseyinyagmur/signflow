module AiContracts
  class ProviderFactory
    def self.build(env: ENV)
      config = SignflowAgent::ProviderConfig.new(env: env)
      raise SignflowAgent::Error, "web_requires_gemini" unless config.name == "gemini"
      raise SignflowAgent::Error, "synthetic_data_required" unless env["SIGNFLOW_SYNTHETIC_DATA"] == "true"

      config.check_consent!
      # Only accessed at explicit runtime, never in boot/assets/test discovery.
      key = env["GEMINI_API_KEY"]
      raise SignflowAgent::Error, "gemini_key_required" if key.to_s.strip.empty?

      key = SignflowAgent::Secrets.read("GEMINI_API_KEY", env: env, console: nil)
      [ config.build(api_key: key), [ key ] ]
    end
  end
end
