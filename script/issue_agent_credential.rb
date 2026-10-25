# Provisioning by the project operator, not a public API. No password/token output.
# bundle exec rails runner script/issue_agent_credential.rb
begin
  raise "disabled" unless ENV["AGENT_API_ENABLED"] == "true"

  owner = User.find_by!(email: ENV.fetch("SIGNFLOW_OWNER_EMAIL").strip.downcase)
  path = Rails.root.join("tmp", "agent-credential.json")
  # Exclusive creation prevents overwriting a previous credential delivery file.
  File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
    owner.with_lock do
      credential, token = AgentCredential.issue!(user: owner, label: "Local HTTP demo")
      file.write(JSON.generate(credential_id: credential.id, token: token))
      file.flush
    end
  end
  puts "Credential created; protected delivery file: tmp/agent-credential.json (never share or project)."
rescue StandardError
  warn "Credential delivery failed; no secrets printed. Check configuration and existing delivery file privately."
  exit 1
end
