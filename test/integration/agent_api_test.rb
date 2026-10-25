require "test_helper"
require "active_support/testing/constant_stubbing"

class AgentApiTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::ConstantStubbing

  setup do
    @previous_flag = ENV["AGENT_API_ENABLED"]
    ENV["AGENT_API_ENABLED"] = "true"
    @owner = create_user
    @template = create_template(user: @owner)
    @version = @template.current_version
    @credential, @token = AgentCredential.issue!(user: @owner, label: "API test", expires_at: 1.day.from_now)
    @headers = { "Authorization" => "Bearer #{@token}", "Idempotency-Key" => "stage1-request-0001" }
    @payload = { template_id: @template.id, template_version_id: @version.id,
      values: { alici_adi: "Deniz", hizmet: "Development", ucret: "100 TRY" },
      document: { title: "API draft", recipient_email: "recipient@example.com", expires_at: 1.day.from_now.iso8601 } }
  end

  teardown do
    ENV["AGENT_API_ENABLED"] = @previous_flag
  end

  test "feature flag is closed unless explicitly true" do
    [ nil, "false", "1" ].each do |flag|
      ENV["AGENT_API_ENABLED"] = flag
      post "/api/v1/drafts", params: @payload, headers: @headers, as: :json
      assert_response :not_found
      get manifest_path, headers: @headers
      assert_response :not_found
    end
    assert_equal 0, @owner.agent_requests.count
  end

  test "requires bearer authentication and ignores web cookies" do
    post session_path, params: { email: @owner.email, password: "secure-password-123" }
    [ nil, "Basic #{@token}", "Bearer bad", "Bearer #{@credential.token_digest}" ].each do |authorization|
      get manifest_path, headers: { "Authorization" => authorization }
      assert_response :unauthorized
    end
    get "#{manifest_path}?token=#{@token}"
    assert_response :unauthorized
    @credential.revoke!
    get manifest_path, headers: @headers
    assert_response :unauthorized
  end

  test "token expiry also denies creates and replays" do
    create_draft
    travel_to @credential.expires_at, with_usec: true do
      assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
      assert_response :unauthorized
    end
  end

  test "manifest and draft use the pinned immutable version" do
    Templates::Manage.new(user: @owner).update!(@template.id, title: "New", content: "Other {{hizmet}}")
    get manifest_path, headers: @headers
    assert_response :success
    assert_equal %w[alici_adi hizmet ucret], response.parsed_body.fetch("variables")
    assert_not response.parsed_body.key?("content")
    assert_difference [ "Document.count", "AgentRequest.count" ], 1 do
      create_draft
    end
    assert_response :created
    document = @owner.documents.last
    assert document.draft?
    assert_nil document.signing_token_digest
    assert_nil document.signed_at
    assert_equal @version.id, document.template_version_id
    assert_equal "Deniz için Development. Ücret: 100 TRY.", document.content
    assert_equal false, response.parsed_body.fetch("replayed")
    assert_response_fields(document)
    get "/api/v1/drafts/#{document.id}", headers: @headers
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "draft", response.parsed_body.fetch("status")
  end

  test "same key and canonical payload replay one document even after credential rotation" do
    create_draft
    id = response.parsed_body.fetch("id")
    _, rotated = AgentCredential.issue!(user: @owner, label: "Rotation", expires_at: 1.day.from_now)
    @headers["Authorization"] = "Bearer #{rotated}"
    @payload = @payload.to_a.reverse.to_h
    @payload[:values] = @payload[:values].to_a.reverse.to_h
    assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
    assert_response :ok
    assert_equal id, response.parsed_body.fetch("id")
    assert_equal true, response.parsed_body.fetch("replayed")
    @payload[:document][:title] = "Changed"
    assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
    assert_response :conflict
    assert_equal "API draft", @owner.documents.find(id).title
  end

  test "tenant isolation rejects mismatched templates versions and documents" do
    other = create_user(email: "other@example.com")
    other_template = create_template(user: other)
    get "/api/v1/templates/#{other_template.id}/versions/#{other_template.current_version_id}", headers: @headers
    assert_response :not_found
    @payload[:template_version_id] = other_template.current_version_id
    assert_no_difference("Document.count") { create_draft }
    assert_response :not_found
    @payload[:template_id] = other_template.id
    assert_no_difference("Document.count") { create_draft }
    assert_response :not_found
    @payload[:template_id], @payload[:template_version_id] = @template.id, @version.id
    create_draft
    id = response.parsed_body.fetch("id")
    _, token = AgentCredential.issue!(user: other, label: "Other", expires_at: 1.day.from_now)
    get "/api/v1/drafts/#{id}", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :not_found
    manual = create_document(user: @owner)
    get "/api/v1/drafts/#{manual.id}", headers: @headers
    assert_response :not_found
    # A cookie for another user cannot change the bearer principal.
    post session_path, params: { email: other.email, password: "secure-password-123" }
    get manifest_path, headers: @headers
    assert_response :success
  end

  test "each tenant may use the same idempotency key" do
    create_draft
    other = create_user(email: "other@example.com")
    template = create_template(user: other)
    _, token = AgentCredential.issue!(user: other, label: "Other", expires_at: 1.day.from_now)
    @payload[:template_id], @payload[:template_version_id] = template.id, template.current_version_id
    @headers["Authorization"] = "Bearer #{token}"
    assert_difference("Document.count", 1) { create_draft }
    assert_response :created
    assert_equal other.id, Document.last.user_id
  end

  test "rejects malformed payloads and forbidden fields without writes" do
    [ { status: "pending" }, { content: "forged" }, { user_id: @owner.id }, { signed_at: Time.current.iso8601 } ].each do |attack|
      original = @payload.deep_dup
      @payload[:document].merge!(attack)
      assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
      assert_response :unprocessable_entity
      @payload = original
    end
    @payload[:values][:unknown_secret] = "do not echo"
    create_draft
    assert_response :unprocessable_entity
    assert_not_includes response.body, "unknown_secret"
    assert_not_includes response.body, "do not echo"
    @payload[:values] = { hizmet: { nested: "bad" } }
    create_draft
    assert_response :unprocessable_entity
    @payload[:document] = { title: "" }
    @payload[:values] = { alici_adi: "Deniz", hizmet: "Valid", ucret: "100" }
    @payload[:document][:recipient_email] = "invalid"
    assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
    assert_response :unprocessable_entity
  end

  test "requires a bounded idempotency key and JSON object" do
    [ nil, "short", "a" * 129 ].each do |key|
      @headers["Idempotency-Key"] = key
      create_draft
      assert_response :bad_request
    end
    @headers["Idempotency-Key"] = "valid-request-0001"
    post "/api/v1/drafts", params: "{", headers: @headers.merge("CONTENT_TYPE" => "application/json")
    assert_response :bad_request
    post "/api/v1/drafts", params: [ 1, 2 ], headers: @headers, as: :json
    assert_response :bad_request
    post "/api/v1/drafts", params: @payload, headers: @headers
    assert_response :unsupported_media_type
    post "/api/v1/drafts", params: JSON.generate(padding: "a" * 65536), headers: @headers.merge("CONTENT_TYPE" => "application/json")
    assert_response :content_too_large
  end

  test "database constraints and transaction prevent orphan drafts on failure" do
    create_draft
    existing = AgentRequest.last
    assert_raises(ActiveRecord::RecordNotUnique) do
      AgentRequest.transaction(requires_new: true) { AgentRequest.insert_all!([ existing.attributes.except("id") ]) }
    end
    @headers["Idempotency-Key"] = "different-request-0002"
    stub_const(Agents::CreateDraft, :REQUEST_MODEL, Class.new do
      def self.create!(*)
        raise ActiveRecord::RecordInvalid.new(AgentRequest.new)
      end
    end) do
      assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
      assert_response :unprocessable_entity
    end
  end

  test "agent has no dispatch sign or edit capability and does not bypass web CSRF" do
    create_draft
    document = @owner.documents.last
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert ApplicationController.forgery_protection_origin_check
    assert_no_difference("Document.count") do
      %w[send_for_signature sign].each do |action|
        post "/api/v1/drafts/#{document.id}/#{action}", headers: @headers, as: :json
        assert_response :not_found
      end
      patch "/api/v1/drafts/#{document.id}", params: { status: "pending" }, headers: @headers, as: :json
      assert_response :not_found
      post send_for_signature_document_path(document), headers: @headers, as: :json
      assert_includes [ 401, 422 ], response.status
    end
    assert document.reload.draft?
    assert_nil document.signing_token_digest
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "agent draft hands off to the existing CSRF protected human and recipient workflow" do
    create_draft
    document = @owner.documents.last
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    origin = { "Origin" => "http://www.example.com" }
    get new_session_path
    post session_path, headers: origin, params: { email: @owner.email, password: "secure-password-123", authenticity_token: form_token(session_path) }
    get document_path(document)
    post send_for_signature_document_path(document), headers: origin,
      params: { authenticity_token: form_token(send_for_signature_document_path(document)) }
    assert_response :success
    uri = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
    token = URI.decode_www_form(uri.fragment).to_h.fetch("token")
    recipient = open_session
    recipient.get signing_path
    recipient.post signing_access_path, headers: origin, params: { token: token, authenticity_token: form_token(signing_access_path, recipient) }
    recipient.follow_redirect!
    recipient.post signing_path, headers: origin, params: { token: token, authenticity_token: form_token(signing_path, recipient),
      signature_acceptance: { signer_name: "Deniz", accepted: "1" } }
    recipient.assert_redirected_to signing_complete_path
    assert document.reload.signed?
    assert_nil document.signing_token_digest
    get "/api/v1/drafts/#{document.id}", headers: @headers
    assert_equal "signed", response.parsed_body.fetch("status")
    assert_no_difference("Document.count") { create_draft }
    assert_equal "signed", response.parsed_body.fetch("status")
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "logs and responses do not disclose credentials or signing secrets" do
    output = StringIO.new
    logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(output))
    previous_logger = Rails.logger
    Rails.logger = logger
    create_draft
    assert_response :created
    [ @token, @credential.token_digest, "recipient@example.com", "Development" ].each do |secret|
      assert_not_includes output.string, secret
    end
    assert_not_includes response.body, @token
    assert_not_includes response.body, "signing_token"
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(
      "HTTP_AUTHORIZATION" => "Bearer #{@token}", "Idempotency-Key" => @headers["Idempotency-Key"])
    assert_equal "[FILTERED]", filtered["HTTP_AUTHORIZATION"]
    assert_equal "[FILTERED]", filtered["Idempotency-Key"]
  ensure
    Rails.logger = previous_logger
  end

  test "unexpected failure is generic and does not expose the exception" do
    stub_const(Agents::CreateDraft, :REQUEST_MODEL, Class.new do
      def self.create!(*)
        raise "private simulated failure"
      end
    end) do
      assert_no_difference([ "Document.count", "AgentRequest.count" ]) { create_draft }
      assert_response :internal_server_error
      assert_equal({ "error" => "internal_error" }, response.parsed_body)
      assert_not_includes response.body, "private simulated failure"
    end
  end

  private

  def manifest_path
    "/api/v1/templates/#{@template.id}/versions/#{@version.id}"
  end

  def create_draft
    post "/api/v1/drafts", params: @payload, headers: @headers, as: :json
  end

  def assert_response_fields(document)
    assert_equal document.id, response.parsed_body.fetch("id")
    assert_equal document_path(document), response.parsed_body.fetch("review_path")
    assert_equal %w[content id replayed review_path status template_version_id title], response.parsed_body.keys.sort
  end

  def form_token(action, client = self)
    Nokogiri::HTML(client.response.body).at_css("form[action='#{action}'] input[name='authenticity_token']")["value"]
  end
end
