require "test_helper"

class AgentCredentialsTest < ActionDispatch::IntegrationTest
  setup do
    @flag = ENV["AGENT_API_ENABLED"]
    ENV["AGENT_API_ENABLED"] = "true"
    @csrf = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @owner = create_user
    @origin = { "Origin" => "http://www.example.com" }
  end

  teardown do
    ENV["AGENT_API_ENABLED"] = @flag
    ActionController::Base.allow_forgery_protection = @csrf
  end

  test "credential screens require a session and creation requires CSRF and same origin" do
    get agent_credentials_path
    assert_redirected_to new_session_path
    login
    assert ApplicationController.forgery_protection_origin_check
    get agent_credentials_path
    assert_select "form[action='#{agent_credentials_path}'] input[name='authenticity_token']"
    csrf = form_token(agent_credentials_path)
    assert_no_difference("AgentCredential.count") do
      post agent_credentials_path, headers: @origin, params: { agent_credential: { label: "Demo", lifetime_days: "7" } }
      assert_response :unprocessable_entity
      post agent_credentials_path, headers: { "Origin" => "https://evil.example" }, params: { authenticity_token: csrf, agent_credential: { label: "Demo", lifetime_days: "7" } }
      assert_response :unprocessable_entity
    end
  end

  test "token is delivered once without being placed in flash cookie or subsequent pages" do
    login
    get agent_credentials_path
    assert_difference("AgentCredential.count", 1) do
      post agent_credentials_path, headers: @origin, params: { authenticity_token: form_token(agent_credentials_path),
        agent_credential: { label: "Local demo", lifetime_days: "7", user_id: -1 } }
    end
    assert_response :success
    token = Nokogiri::HTML(response.body).at_css("#agent-token").text.strip
    assert_match AgentCredential::TOKEN_PATTERN, token
    credential = @owner.agent_credentials.last
    assert_equal credential, AgentCredential.authenticate(token)
    assert_equal @owner.id, credential.user_id
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_equal "same-origin", response.headers["Referrer-Policy"]
    assert_empty flash
    assert_not_includes session.to_hash.to_json, token
    assert_not_includes credential.attributes.to_json, token
    assert_select "[data-turbo-temporary] #agent-token"
    get agent_credentials_path
    assert_response :success
    assert_not_includes response.body, token
    assert_not_includes response.body, credential.token_digest
    assert_select "#agent-token", count: 0
    get "/agent_credentials/#{credential.id}"
    assert_response :not_found
  end

  test "listing and revoking are owner scoped and revoked credentials stop API access" do
    own, token = AgentCredential.issue!(user: @owner, label: "Mine", expires_at: 1.day.from_now)
    other, = AgentCredential.issue!(user: create_user(email: "other@example.com"), label: "Other private label", expires_at: 1.day.from_now)
    login
    get agent_credentials_path
    assert_includes response.body, "Mine"
    assert_not_includes response.body, "Other private label"
    assert_not_includes response.body, other.token_digest
    csrf = global_form_token
    post revoke_agent_credential_path(other), headers: @origin, params: { authenticity_token: csrf }
    assert_response :not_found
    assert_nil other.reload.revoked_at
    get agent_credentials_path
    post revoke_agent_credential_path(own), headers: @origin, params: { authenticity_token: form_token(revoke_agent_credential_path(own)) }
    assert_redirected_to agent_credentials_path
    assert own.reload.revoked_at
    assert_nil AgentCredential.authenticate(token)
    get "/api/v1/templates/1/versions/1", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :unauthorized
  end

  test "API shutdown blocks new credentials but still allows viewing and revocation" do
    own, = AgentCredential.issue!(user: @owner, label: "Existing", expires_at: 1.day.from_now)
    ENV["AGENT_API_ENABLED"] = nil
    login
    get agent_credentials_path
    assert_response :success
    assert_select "form[action='#{agent_credentials_path}']", count: 0
    assert_no_difference("AgentCredential.count") do
      post agent_credentials_path, headers: @origin, params: { authenticity_token: global_form_token, agent_credential: { label: "New", lifetime_days: "7" } }
      assert_response :not_found
    end
    get agent_credentials_path
    post revoke_agent_credential_path(own), headers: @origin, params: { authenticity_token: form_token(revoke_agent_credential_path(own)) }
    assert_redirected_to agent_credentials_path
    assert own.reload.revoked_at
  end

  test "invalid labels and lifetimes never create credentials and labels are escaped" do
    login
    [ [ "", "7" ], [ "Demo", "365" ], [ "Demo", "7junk" ] ].each do |label, days|
      get agent_credentials_path
      assert_no_difference("AgentCredential.count") do
        post agent_credentials_path, headers: @origin, params: { authenticity_token: form_token(agent_credentials_path), agent_credential: { label: label, lifetime_days: days } }
      end
      assert_response :unprocessable_entity
      assert_select "#agent-token", count: 0
    end
    AgentCredential.issue!(user: @owner, label: '<script id="attack">test</script>', expires_at: 1.day.from_now)
    get agent_credentials_path
    assert_select "script#attack", count: 0
    assert_includes response.body, "&lt;script"
  end

  test "bearer credentials cannot manage web credentials and revoke also requires CSRF" do
    own, token = AgentCredential.issue!(user: @owner, label: "Existing", expires_at: 1.day.from_now)
    get agent_credentials_path, headers: { "Authorization" => "Bearer #{token}" }, as: :json
    assert_response :unauthorized
    login
    post revoke_agent_credential_path(own), headers: @origin
    assert_response :unprocessable_entity
    assert_nil own.reload.revoked_at
  end

  private

  def login
    get new_session_path
    post session_path, headers: @origin, params: { authenticity_token: form_token(session_path), email: @owner.email, password: "secure-password-123" }
    assert_redirected_to dashboard_path
    follow_redirect!
  end

  def form_token(path)
    Nokogiri::HTML(response.body).at_css("form[action='#{path}'] input[name='authenticity_token']")["value"]
  end

  def global_form_token
    Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
  end
end
