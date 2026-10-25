require_relative "support/signflow_agent"
require "optparse"

# Real-provider CLI. No Rails boot, database, shell, cookies or signing capability.
job = nil
begin
  options = { job: nil, resume: false }
  OptionParser.new do |parser|
    parser.on("--job ID") { |id| options[:job] = id }
    parser.on("--resume") { options[:resume] = true }
  end.parse!
  raise SignflowAgent::Error, "usage_requires_job_id" unless options[:job] && ARGV.empty?
  raise SignflowAgent::Error, "synthetic_data_confirmation_required" unless ENV["SIGNFLOW_SYNTHETIC_DATA"] == "true"

  template_id = Integer(ENV.fetch("SIGNFLOW_TEMPLATE_ID"), 10)
  version_id = Integer(ENV.fetch("SIGNFLOW_TEMPLATE_VERSION_ID"), 10)
  [ template_id, version_id ].each { |id| SignflowAgent.positive_id!(id) }
  base = ENV.fetch("SIGNFLOW_BASE_URL")
  # Validate the trusted base URL before reading any secret interactively.
  SignflowAgentHttp::Client.new(base_url: base, token: "validation-only", allow_loopback_http: ENV["SIGNFLOW_ALLOW_LOOPBACK_HTTP"] == "true")
  job = SignflowAgent::Job.new(directory: File.expand_path("../tmp/llm-jobs", __dir__), id: options[:job],
    binding: { "base_url" => base, "template_id" => template_id, "version_id" => version_id })
  if !options[:resume] && job.data["payload"]
    raise SignflowAgent::Error, "existing_payload_use_resume"
  end
  config = options[:resume] ? nil : SignflowAgent::ProviderConfig.new
  config&.check_consent!
  token = SignflowAgent::Secrets.read("SIGNFLOW_API_TOKEN")
  api = SignflowAgentHttp::Client.new(base_url: base, token: token,
    allow_loopback_http: ENV["SIGNFLOW_ALLOW_LOOPBACK_HTTP"] == "true")
  provider_key = options[:resume] ? nil : SignflowAgent::Secrets.read(config.secret_name)
  tools = SignflowAgent::Tools.new(api: api, job: job, secrets: [ token, provider_key ].compact,
    observer: ->(event) { puts JSON.generate(event) })
  if options[:resume]
    result = tools.resume
    summary = { mode: "deterministic_job_recovery_not_new_llm_call", model_calls: 0 }
  else
    provider = config.build(api_key: provider_key)
    provider.verify_model!
    puts "Model erişimi doğrulandı. Yalnız sentetik veri girin; parola/anahtar girmeyin."
    print "Sözleşme talebi: "
    input = STDIN.gets&.chomp
    runner = SignflowAgent::Runner.new(provider: provider, tools: tools)
    result = runner.run(input: input,
      ask: ->(fields) do
        puts "Eksik bilgileri tamamlayın: #{fields.map { |field| SignflowAgent::Tools::FIELD_LABELS.fetch(field) }.join(', ')}"
        STDIN.gets&.chomp
      end,
      confirm: ->(payload) do
        puts "Çıkarılan sentetik alanlar (henüz taslak oluşturulmadı):"
        puts JSON.pretty_generate(payload)
        print "Alanlar doğru mu? Taslak oluşturmak için EVET yazın (imzaya göndermez): "
        STDIN.gets&.strip == "EVET"
      end)
    summary = { mode: "real_provider", provider: config.name, configured_tier: config.tier, model: provider.model, model_calls: runner.model_calls,
      message_http_attempts: provider.message_attempts, successful_response_usage: runner.usage }
  end
  puts JSON.generate(summary.merge(tools: tools.events, document: result))
  puts "İnceleme yolu web oturumu gerektirir. Gönderim ve imza yalnız SignFlow web akışındadır."
rescue SignflowAgent::Error => error
  warn "SignFlow Agent: #{error.message}. Başarı doğrulanmadı; mevcut iş kaydını koruyun."
  exit 1
rescue StandardError
  warn "SignFlow Agent: invalid_configuration_or_unexpected_error. Gizli hata ayrıntıları yazdırılmadı."
  exit 1
ensure
  job&.close
end
