# Read-only Rails runner diagnostic: no provider construction or network calls.
# Never print ENV, credentials, key lengths/fingerprints or provider responses.
abort "Run this diagnostic only in local development/test" unless Rails.env.development? || Rails.env.test?

config = SignflowAgent::ProviderConfig.new
safe_model = config.model.match?(/\Agemini-[a-z0-9.-]{1,100}\z/) ? config.model : "invalid_or_not_gemini"
dotenv_enabled = !!defined?(Dotenv::Rails)
loaded_files = if dotenv_enabled
  Dotenv::Rails.files.select { |file| Rails.root.join(file).file? }
else
  []
end
puts JSON.generate(
  process: "fresh_rails_runner_not_existing_web_server",
  rails_environment: Rails.env,
  dotenv_enabled: dotenv_enabled,
  existing_dotenv_files_in_load_order: loaded_files,
  provider: config.name,
  model: safe_model,
  matches_reported_model: config.model == "gemini-2.5-flash",
  gemini_key_configured: !ENV["GEMINI_API_KEY"].to_s.strip.empty?,
  web_enabled: ENV["AI_CONTRACTS_ENABLED"] == "true",
  synthetic_data: ENV["SIGNFLOW_SYNTHETIC_DATA"] == "true",
  free_mode: config.tier == "free",
  free_tier_confirmed: ENV["SIGNFLOW_GEMINI_FREE_TIER_CONFIRMED"] == "true",
  paid_allowed: ENV["SIGNFLOW_ALLOW_PAID_LLM"] == "true",
  model_lookup_method: "GET",
  model_lookup_url: safe_model == "invalid_or_not_gemini" ? nil : "https://generativelanguage.googleapis.com/v1beta/models/#{safe_model}",
  generation_method: "POST",
  generation_url: safe_model == "invalid_or_not_gemini" ? nil : "https://generativelanguage.googleapis.com/v1beta/models/#{safe_model}:generateContent",
  network_calls: 0
)
