require "test_helper"
require "active_support/testing/constant_stubbing"
require_relative "../../script/support/signflow_agent"

class AiContractsTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::ConstantStubbing

  class Provider
    def initialize(responses) = @responses = responses
    def verify_model! = true
    def reply(**) = @responses.shift || raise(SignflowAgent::Error, "gemini_http_429")
  end

  setup do
    @flag = ENV["AI_CONTRACTS_ENABLED"]
    ENV["AI_CONTRACTS_ENABLED"] = "true"
    @csrf = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @owner = create_user
    @template = create_template(user: @owner, content: "{{hizmet}}: {{ucret}}")
    @other = create_user(email: "other@example.com")
    @foreign = create_template(user: @other, content: "Foreign secret")
    @origin = { "Origin" => "http://www.example.com" }
    @deadline = 2.days.from_now.iso8601
    @candidate = { "values" => { "hizmet" => "Web demo", "ucret" => "25 bin TL" },
      "document" => { "recipient_name" => "Ahmet", "recipient_email" => "ahmet@example.com", "expires_at" => @deadline } }
    @input = "Ahmet ahmet@example.com Web demo 25 bin TL #{@deadline}"
  end

  teardown do
    ENV["AI_CONTRACTS_ENABLED"] = @flag
    ActionController::Base.allow_forgery_protection = @csrf
    AiContracts::Conversations.reset! if defined?(AiContracts::Conversations)
  end

  test "session ownership feature flag and CSRF protect the new workflow" do
    get new_ai_contract_path
    assert_redirected_to new_session_path
    login
    get new_ai_contract_path
    assert_select "option[value='#{@template.current_version_id}']"
    assert_select "option[value='#{@foreign.current_version_id}']", count: 0
    assert_no_difference("AiContractConversation.count") do
      post ai_contracts_path, params: { template_version_id: @template.current_version_id, synthetic: "1" }, headers: @origin
      assert_response :unprocessable_entity
      get new_ai_contract_path
      post ai_contracts_path, params: { authenticity_token: token(ai_contracts_path), template_version_id: @template.current_version_id, synthetic: "1" }, headers: { "Origin" => "null" }
      assert_response :unprocessable_entity
    end
    get new_ai_contract_path
    post ai_contracts_path, params: { authenticity_token: token(ai_contracts_path), template_version_id: @foreign.current_version_id, synthetic: "1" }, headers: @origin
    assert_response :not_found
    ENV["AI_CONTRACTS_ENABLED"] = "false"
    get new_ai_contract_path
    assert_response :not_found
  end

  test "missing information preview explicit approval duplicate requests and normal signed workflow" do
    login
    start_conversation
    question = { "content" => [ { "type" => "text", "text" => '{"type":"question","fields":["recipient_email","expires_at"]}' } ], "stop_reason" => "end_turn" }
    responses = [ call("get_template_version"), question, call("create_draft", @candidate) ]
    with_provider(responses) do
      assert_no_difference("Document.count") { post_message("Ahmet Web demo 25 bin TL", step: 0) }
      assert_response :redirect
      follow_redirect!
      assert_select "[data-missing]", text: /Alıcı e-postası/
      assert_no_difference("Document.count") { post_message("ahmet@example.com #{@deadline}", step: 1) }
      follow_redirect!
      assert_select "#contract-preview", text: /Web demo: 25 bin TL/
      assert_select "form[action='#{draft_ai_contract_path(@conversation)}']"
      assert_no_difference("Document.count") { post_message("ahmet@example.com #{@deadline}", step: 1) }
      assert_response :redirect
      follow_redirect!
      assert_difference("Document.count", 1) do
        approve(user_id: @other.id, template_version_id: @foreign.current_version_id,
          document: { user_id: @other.id, status: "signed", content: "Untrusted browser payload" })
      end
      document = @owner.documents.last
      assert document.draft?
      assert_equal @owner.id, document.user_id
      assert_equal 0, @other.documents.count
      assert_equal @template.current_version_id, document.template_version_id
      assert_equal "Web demo: 25 bin TL", document.content
      assert_nil document.signing_token_digest
      get ai_contract_path(@conversation)
      assert_select "a[href='#{document_path(document)}']", text: "Oluşturulan taslağı aç"
      assert_no_difference("Document.count") { approve }
      assert_redirected_to document_path(document)
      get documents_path
      assert_select "a[href='#{document_path(document)}']"
      get document_path(document)
      post send_for_signature_document_path(document), headers: @origin, params: { authenticity_token: token(send_for_signature_document_path(document)) }
      assert_response :success
      link = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
      signing_token = URI.decode_www_form(link.fragment).to_h.fetch("token")
      recipient = open_session
      recipient.get signing_path
      recipient.post signing_access_path, headers: @origin, params: { token: signing_token, authenticity_token: token(signing_access_path, recipient) }
      recipient.follow_redirect!
      recipient.post signing_path, headers: @origin, params: { token: signing_token, authenticity_token: token(signing_path, recipient), signature_acceptance: { signer_name: "Ahmet", accepted: "1" } }
      recipient.assert_redirected_to signing_complete_path
      assert document.reload.signed?
    end
  end

  test "foreign conversations early approval forged payload and bearer cannot authorize writes" do
    login
    start_conversation
    assert_no_difference("Document.count") { approve }
    assert_response :unprocessable_entity
    get new_session_path
    post session_path, headers: @origin, params: { authenticity_token: token(session_path), email: @other.email, password: "secure-password-123" }
    get new_ai_contract_path
    # No authorized draft form exists for a foreign conversation. Use this
    # session's global token so the assertion reaches owner authorization.
    csrf = Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
    get ai_contract_path(@conversation)
    assert_response :not_found
    post draft_ai_contract_path(@conversation), headers: @origin, params: { authenticity_token: csrf }
    assert_response :not_found
  end

  test "hallucinations forbidden tools provider errors and secrets fail without creating a draft" do
    login
    [ [ "create_draft", @candidate.deep_merge("document" => { "recipient_email" => "invented@example.com" }) ],
      [ "create_draft", @candidate.deep_merge("values" => { "ucret" => "25 TL" }) ],
      [ "create_draft", @candidate.deep_merge("document" => { "expires_at" => "yesterday" }) ],
      [ "send_for_signature", {} ], [ "create_draft", @candidate.merge("endpoint" => "https://evil.example") ] ].each do |name, input|
      start_conversation
      with_provider([ call("get_template_version"), call(name, input) ]) do
        assert_no_difference("Document.count") { post_message(@input) }
        assert_response :unprocessable_entity
        assert_select "[role='alert']"
        assert_select "#contract-preview", count: 0
      end
    end
  end

  test "provider failure does not leak secrets or permit retrying a charged message" do
    login
    start_conversation
    with_provider([]) do
      assert_no_difference("Document.count") { post_message(@input) }
      assert_response :unprocessable_entity
      assert_not_includes response.body, "private-test-key"
      assert_select "[role='alert']", text: /gemini_http_429/
      post_message(@input)
      assert_response :unprocessable_entity
      assert_select "[role='alert']", text: /conversation_failed_start_new/
    end
  end

  test "message and approval reject missing tokens and foreign origins and bearer alone is not a session" do
    login
    start_conversation
    csrf = token(ai_contract_path(@conversation))
    [ message_ai_contract_path(@conversation), draft_ai_contract_path(@conversation) ].each do |path|
      assert_no_difference("Document.count") do
        post path, headers: @origin, params: { prompt: @input, step: "0" }
        assert_response :unprocessable_entity
        post path, headers: { "Origin" => "https://evil.example" }, params: { authenticity_token: csrf, prompt: @input, step: "0" }
        assert_response :unprocessable_entity
      end
    end
    credential, bearer = AgentCredential.issue!(user: @owner, label: "Isolated", expires_at: 1.day.from_now)
    anonymous = open_session
    anonymous.get ai_contract_path(@conversation), headers: { "Authorization" => "Bearer #{bearer}" }
    anonymous.assert_redirected_to new_session_path
    assert credential.active?
  end

  test "refresh replay and conflicting message do not invoke more model calls" do
    login
    start_conversation
    question = { "content" => [ { "type" => "text", "text" => '{"type":"question","fields":["recipient_email"]}' } ], "stop_reason" => "end_turn" }
    with_provider([ call("get_template_version"), question ]) do
      post_message("Ahmet Web demo 25 bin TL")
      follow_redirect!
      get ai_contract_path(@conversation)
      assert_response :success
      post_message("Ahmet Web demo 25 bin TL")
      assert_response :redirect
      follow_redirect!
      post_message("Different payload")
      assert_response :conflict
      assert_no_difference("Document.count") { approve }
      assert_response :unprocessable_entity
    end
  end

  test "preview escapes user text and deadline is rechecked on human approval" do
    login
    start_conversation
    deadline = 1.minute.from_now.iso8601
    candidate = @candidate.deep_dup
    candidate["values"]["hizmet"] = "<script>alert(1)</script>"
    candidate["document"]["expires_at"] = deadline
    with_provider([ call("get_template_version"), call("create_draft", candidate) ]) do
      post_message("Ahmet ahmet@example.com 25 bin TL <script>alert(1)</script> #{deadline}")
      follow_redirect!
      assert_select "#contract-preview", text: /<script>/
      assert_select "#contract-preview script", count: 0
      assert_not_includes response.body, "private-test-key"
      travel_to Time.iso8601(deadline) do
        assert_no_difference("Document.count") { approve }
        assert_response :unprocessable_entity
        assert_select "[role='alert']", text: /invalid_deadline/
      end
    end
  end

  test "synthetic consent and web model quota fail closed" do
    login
    get new_ai_contract_path
    assert_no_difference("AiContractConversation.count") do
      post ai_contracts_path, headers: @origin, params: { authenticity_token: token(ai_contracts_path), template_version_id: @template.current_version_id }
      assert_response :unprocessable_entity
    end
    start_conversation
    24.times { AiContracts::Quota.consume!(@owner.id, :model) }
    with_provider([]) do
      post_message(@input)
      assert_response :too_many_requests
      assert_equal "600", response.headers["Retry-After"]
    end
  end

  test "every AI write requires a web session even with a valid anonymous CSRF token" do
    login
    start_conversation
    anonymous = open_session
    assert_no_difference([ "Document.count", "AiContractConversation.count" ]) do
      [ ai_contracts_path, message_ai_contract_path(@conversation), draft_ai_contract_path(@conversation) ].each do |path|
        # Authentication resets anonymous sessions after every denied request.
        anonymous.get root_path
        csrf = Nokogiri::HTML(anonymous.response.body).at_css("meta[name='csrf-token']")["content"]
        anonymous.post path, headers: @origin, params: { authenticity_token: csrf, prompt: @input,
          step: "0", template_version_id: @template.current_version_id, synthetic: "1" }
        anonymous.assert_redirected_to new_session_path
      end
    end
  end

  test "model cannot invoke signing and a secret prompt is filtered from logs and HTML" do
    login
    start_conversation
    with_provider([ call("get_template_version"), call("sign_document") ]) do
      assert_no_difference("Document.count") { post_message(@input) }
      assert_response :unprocessable_entity
      assert_select "[role='alert']", text: /unknown_tool/
    end
    start_conversation
    output = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(output))
    with_provider([]) do
      assert_no_difference("Document.count") { post_message("private-test-key") }
      assert_response :unprocessable_entity
      assert_select "[role='alert']", text: /sensitive_input_rejected/
    end
    assert_not_includes response.body, "private-test-key"
    assert_not_includes output.string, "private-test-key"
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(
      "GEMINI_API_KEY" => "private-test-key", "prompt" => "private-test-key")
    assert_equal "[FILTERED]", filtered["GEMINI_API_KEY"]
    assert_equal "[FILTERED]", filtered["prompt"]
  ensure
    Rails.logger = previous_logger if previous_logger
  end

  private

  def call(name, input = {})
    { "content" => [ { "type" => "tool_use", "id" => SecureRandom.hex(6), "name" => name, "input" => input } ], "stop_reason" => "tool_use" }
  end

  def with_provider(responses)
    fake = Class.new do
      define_singleton_method(:build) { [ AiContractsTest::Provider.new(responses), [ "private-test-key" ] ] }
    end
    stub_const(AiContracts, :ProviderFactory, fake) { yield }
  end

  def login
    get new_session_path
    post session_path, headers: @origin, params: { authenticity_token: token(session_path), email: @owner.email, password: "secure-password-123" }
    assert_response :redirect
  end

  def start_conversation
    get new_ai_contract_path
    post ai_contracts_path, headers: @origin, params: { authenticity_token: token(ai_contracts_path), template_version_id: @template.current_version_id, synthetic: "1" }
    assert_response :redirect
    @conversation = AiContractConversation.order(:id).last
    follow_redirect!
  end

  def post_message(prompt, step: 0)
    post message_ai_contract_path(@conversation), headers: @origin, params: { authenticity_token: token(message_ai_contract_path(@conversation)), prompt: prompt, step: step }
  end

  def approve(**extra)
    post draft_ai_contract_path(@conversation), headers: @origin,
      params: extra.merge(authenticity_token: token(draft_ai_contract_path(@conversation)))
  end

  def token(action, client = self)
    html = Nokogiri::HTML(client.response.body)
    field = html.at_css("form[action='#{action}'] input[name='authenticity_token']")
    field ? field["value"] : html.at_css("meta[name='csrf-token']")["content"]
  end
end
