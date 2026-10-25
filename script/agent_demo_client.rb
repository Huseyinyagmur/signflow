require_relative "support/agent_http_client"
require "io/console"

# Run with a synthetic JSON payload file and a stable key. Never logs secrets/content.
begin
  raise SignflowAgentHttp::Error, "usage_ruby_script_agent_demo_client_payload_json" unless ARGV.size == 1

  payload = JSON.parse(File.read(ARGV.first))
  key = ENV.fetch("SIGNFLOW_IDEMPOTENCY_KEY")
  raise SignflowAgentHttp::Error, "invalid_idempotency_key" unless key.match?(/\A[A-Za-z0-9_-]{16,128}\z/)

  token = ENV["SIGNFLOW_API_TOKEN"] || IO.console&.getpass("API token (hidden): ")
  client = SignflowAgentHttp::Client.new(base_url: ENV.fetch("SIGNFLOW_BASE_URL"), token: token,
    allow_loopback_http: ENV["SIGNFLOW_ALLOW_LOOPBACK_HTTP"] == "true")
  client.request(:get, "/api/v1/templates/#{Integer(payload.fetch('template_id'))}/versions/#{Integer(payload.fetch('template_version_id'))}", expected: 200)
  created = client.request(:post, "/api/v1/drafts", expected: [ 200, 201 ], payload: payload, key: key)
  initial_status = client.last_status
  replay = client.request(:post, "/api/v1/drafts", expected: 200, payload: payload, key: key)
  raise SignflowAgentHttp::Error, "idempotency_failed" unless created.fetch("id") == replay.fetch("id") && replay.fetch("replayed")

  changed = JSON.parse(JSON.generate(payload))
  changed.fetch("document")["title"] = payload.fetch("document")["title"] == "Different smoke-test payload" ? "Another smoke-test payload" : "Different smoke-test payload"
  client.request(:post, "/api/v1/drafts", expected: 409, payload: changed, key: key)
  current = client.request(:get, "/api/v1/drafts/#{Integer(created.fetch('id'))}", expected: 200)
  raise SignflowAgentHttp::Error, "unsafe_response" if current.keys.any? { |name| name.match?(/token|secret|digest/) }

  puts JSON.generate(client: "deterministic_http_not_llm", manifest: 200, create: initial_status,
    replay: 200, conflict: 409, query: 200, document_id: current.fetch("id"), status: current.fetch("status"))
rescue SignflowAgentHttp::Error => error
  warn error.message
  exit 1
rescue KeyError, ArgumentError, TypeError, JSON::ParserError, SystemCallError
  warn "invalid_demo_configuration"
  exit 1
end
