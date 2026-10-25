require "test_helper"
require "tmpdir"
require_relative "../../script/support/signflow_agent"

class LlmAgentHandoffTest < ActionDispatch::IntegrationTest
  class ApiBridge
    attr_reader :last_status

    def initialize(session, token)
      @session, @token = session, token
    end

    def request(method, path, expected:, payload: nil, key: nil)
      headers = { "Authorization" => "Bearer #{@token}" }
      headers["Idempotency-Key"] = key if key
      @session.public_send(method, path, params: payload, headers: headers, as: :json)
      @last_status = @session.response.status
      raise SignflowAgentHttp::Error.new("unexpected_http_#{@last_status}", status: @last_status) unless Array(expected).include?(@last_status)

      @session.response.parsed_body
    end
  end

  class ScriptedProvider
    def initialize(candidate)
      @calls = [ [ "get_template_version", {} ], [ "create_draft", candidate ], [ "get_draft", {} ] ]
    end

    def reply(**)
      name, input = @calls.shift
      { "content" => [ { "type" => "tool_use", "id" => "tool_#{SecureRandom.hex(4)}", "name" => name, "input" => input } ], "stop_reason" => "tool_use" }
    end
  end

  test "scripted provider uses actual API then human CSRF dispatch and recipient signing" do
    original_flag, original_csrf = ENV["AGENT_API_ENABLED"], ActionController::Base.allow_forgery_protection
    ENV["AGENT_API_ENABLED"] = "true"
    ActionController::Base.allow_forgery_protection = true
    owner = create_user
    template = create_template(user: owner, content: "{{hizmet}}")
    credential, token = AgentCredential.issue!(user: owner, label: "Mock model integration", expires_at: 1.day.from_now)
    directory = Dir.mktmpdir("signflow-llm-integration")
    job = SignflowAgent::Job.new(directory: directory, id: "workflow", binding: { "base_url" => "http://www.example.com", "template_id" => template.id, "version_id" => template.current_version_id })
    deadline = 1.hour.from_now.iso8601
    candidate = { "values" => { "hizmet" => "yazılım" }, "document" => { "recipient_name" => "Ahmet", "recipient_email" => "ahmet@example.com", "expires_at" => deadline } }
    tools = SignflowAgent::Tools.new(api: ApiBridge.new(open_session, token), job: job, secrets: [ token ])
    runner = SignflowAgent::Runner.new(provider: ScriptedProvider.new(candidate), tools: tools)
    assert_difference([ "Document.count", "AgentRequest.count" ], 1) do
      @result = runner.run(input: "Ahmet ahmet@example.com yazılım #{deadline}", ask: ->(_) { flunk }, confirm: ->(_) { true })
    end
    document = owner.documents.find(@result.fetch("id"))
    assert document.draft?
    assert_nil document.signing_token_digest
    assert_equal %w[get_template_version create_draft get_draft], tools.events.map { |event| event.fetch("tool") }
    assert_equal [ 200, 201, 200 ], tools.events.map { |event| event.fetch("http_status") }
    assert_no_difference("Document.count") { assert_equal document.id, tools.resume.fetch("id") }
    assert_equal 3, runner.model_calls
    credential.revoke!
    assert_raises(SignflowAgent::Error) { tools.resume }

    origin = { "Origin" => "http://www.example.com" }
    get new_session_path
    post session_path, headers: origin, params: { email: owner.email, password: "secure-password-123", authenticity_token: csrf(session_path) }
    get document_path(document)
    post send_for_signature_document_path(document), headers: origin, params: { authenticity_token: csrf(send_for_signature_document_path(document)) }
    assert_response :success
    link = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
    signing_token = URI.decode_www_form(link.fragment).to_h.fetch("token")
    recipient = open_session
    recipient.get signing_path
    recipient.post signing_access_path, headers: origin, params: { token: signing_token, authenticity_token: csrf(signing_access_path, recipient) }
    recipient.follow_redirect!
    recipient.post signing_path, headers: origin, params: { token: signing_token, authenticity_token: csrf(signing_path, recipient),
      signature_acceptance: { signer_name: "Ahmet", accepted: "1" } }
    recipient.assert_redirected_to signing_complete_path
    assert document.reload.signed?
  ensure
    job&.close
    if directory
      raise "Unsafe temporary test path" unless File.expand_path(directory).start_with?(File.expand_path(Dir.tmpdir) + File::SEPARATOR) && File.basename(directory).start_with?("signflow-llm-integration")

      FileUtils.remove_entry(directory)
    end
    ENV["AGENT_API_ENABLED"] = original_flag
    ActionController::Base.allow_forgery_protection = original_csrf
  end

  private

  def csrf(action, client = self)
    Nokogiri::HTML(client.response.body).at_css("form[action='#{action}'] input[name='authenticity_token']")["value"]
  end
end
