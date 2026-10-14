# Run only against a disposable, already migrated local PostgreSQL database:
# bundle exec rails runner script/check_render_production.rb (RAILS_ENV=production)
require "uri"
require "nokogiri"

connection = ActiveRecord::Base.connection
database = ActiveRecord::Base.connection_db_config.database
database_host = URI.parse(ENV.fetch("DATABASE_URL")).host
unless Rails.env.production? && connection.adapter_name == "PostgreSQL" &&
    database.end_with?("_production_check") && %w[127.0.0.1 localhost].include?(database_host)
  abort "Use a disposable local PostgreSQL database ending in _production_check; never a live database."
end

class RenderProductionCheck
  def check(condition, message)
    raise message unless condition
  end

  def client
    ActionDispatch::Integration::Session.new(Rails.application).tap do |session|
      session.host! "signflow.test"
      session.https!
    end
  end

  def token(session, action)
    input = Nokogiri::HTML(session.response.body).at_css("form[action='#{action}'] input[name='authenticity_token']")
    check(input, "Missing CSRF token for #{action}")
    input["value"]
  end

  def submit(session, action, params = {}, csrf: token(session, action), origin: "https://signflow.test")
    session.post action, headers: { "Origin" => origin }, params: params.merge(authenticity_token: csrf)
  end

  def redirected(session, path)
    check([ 302, 303 ].include?(session.response.status), "Expected redirect to #{path}, got #{session.response.status}")
    check(URI.parse(session.response.location).path == path, "Unexpected redirect destination")
  end

  def sign(owner, document)
    owner.get "/documents/#{document.id}"
    action = "/documents/#{document.id}/send_for_signature"
    csrf = token(owner, action)
    submit(owner, action, {}, csrf: csrf, origin: "https://untrusted.example")
    check(owner.response.status == 422 && document.reload.draft?, "Cross-origin POST must fail")
    submit(owner, action, {}, csrf: "")
    check(owner.response.status == 422 && document.reload.draft?, "Missing CSRF token must fail")
    submit(owner, action, {}, csrf: csrf)
    check(owner.response.status == 200 && document.reload.pending?, "Sending failed")
    link = URI.parse(Nokogiri::HTML(owner.response.body).at_css("#signing-link")["value"])
    check(link.scheme == "https" && link.host == "signflow.test" && link.query.nil?, "Unsafe signing URL")
    signing_token = URI.decode_www_form(link.fragment).to_h.fetch("token")
    recipient = client
    recipient.get "/sign"
    submit(recipient, "/sign/access", { token: signing_token })
    redirected(recipient, "/sign")
    recipient.follow_redirect!
    text = Nokogiri::HTML(recipient.response.body).at_css(".contract-text").text
    check(text == document.content, "Recipient content differs")
    csrf = token(recipient, "/sign")
    acceptance = { token: signing_token, signature_acceptance: { signer_name: "Demo recipient", accepted: "1" } }
    submit(recipient, "/sign", acceptance, csrf: csrf)
    redirected(recipient, "/sign/complete")
    recipient.follow_redirect!
    check(recipient.response.status == 200, "Confirmation failed")
    check(document.reload.signed? && document.signed_at && document.signer_name == "Demo recipient", "Signature not persisted")
    check(document.signing_token_digest.nil?, "Used token must be revoked")
    submit(recipient, "/sign", acceptance, csrf: csrf)
    check(recipient.response.status == 404, "Replayed token must fail")
  end

  def run
    check(ApplicationController.allow_forgery_protection, "CSRF protection must be enabled")
    check(ApplicationController.forgery_protection_origin_check, "Origin check must be enabled")
    owner = client
    owner.get "/registration/new"
    password = SecureRandom.hex(20)
    email = "production-check-#{SecureRandom.hex(8)}@example.com"
    submit(owner, "/registration", { user: { name: "Production check", email: email,
      password: password, password_confirmation: password } })
    redirected(owner, "/session/new")
    owner.follow_redirect!
    submit(owner, "/session", { email: email, password: password })
    redirected(owner, "/dashboard")
    cookies = Array(owner.response.headers["set-cookie"]).join(";").downcase
    check(cookies.include?("secure") && cookies.include?("httponly") && cookies.include?("samesite=lax"), "Unsafe session cookie")
    owner.follow_redirect!
    check(owner.response.status == 200, "Dashboard failed")
    check(owner.response.headers["Referrer-Policy"] == "same-origin", "Unexpected referrer policy")
    user = User.find_by!(email: email)
    fields = { title: "Production contract", content: "Standalone agreement", recipient_name: "Demo recipient",
      recipient_email: "recipient@example.com", expires_at: 1.day.from_now.iso8601 }
    owner.get "/documents/new"
    submit(owner, "/documents", { document: fields })
    manual = user.documents.last
    redirected(owner, "/documents/#{manual.id}")
    check(manual.template_version_id.nil?, "Standalone contract must remain supported")
    sign(owner, manual)
    puts "PASS: registration, login, secure cookie, manual contract, CSRF/origin, signing and replay rejection"

    owner.get "/templates/new"
    submit(owner, "/templates", { template_revision: { title: "Production template", content: "Agreement: {{hizmet}}" } })
    template = user.templates.last
    redirected(owner, "/templates/#{template.id}")
    action = "/templates/#{template.id}/documents"
    owner.get "#{action}/new"
    csrf = token(owner, action)
    params = { document: fields.except(:content), version_id: template.current_version_id, values: { hizmet: "Consulting" } }
    count = Document.count
    submit(owner, "#{action}/preview", params, csrf: csrf)
    check(owner.response.status == 200 && Document.count == count, "Preview must not persist a document")
    submit(owner, action, params, csrf: csrf)
    generated = user.documents.last
    redirected(owner, "/documents/#{generated.id}")
    check(generated.content == "Agreement: Consulting" && generated.template_version_id == template.current_version_id, "Template snapshot failed")
    sign(owner, generated)
    puts "PASS: PostgreSQL template version association, non-persisting preview, draft, send and signature"

    changed = generated.update(content: "Forbidden change")
    check(!changed && generated.reload.content == "Agreement: Consulting", "Signed contract must be immutable")
    foreign = client
    foreign.get "/documents/#{generated.id}"
    redirected(foreign, "/session/new")
    foreign.host! "untrusted.example"
    foreign.get "/"
    check(foreign.response.status == 403, "Unknown host must be rejected")
    foreign.get "/up"
    check(foreign.response.status == 200, "Health check must accept internal hosts")
    owner.get "/dashboard"
    owner.delete "/session", headers: { "Origin" => "https://signflow.test" },
      params: { authenticity_token: token(owner, "/session") }
    redirected(owner, "/")
    owner.get "/dashboard"
    redirected(owner, "/session/new")
    puts "PASS: immutable signed contract, authentication, host protection, health check and logout"
  end
end

RenderProductionCheck.new.run
