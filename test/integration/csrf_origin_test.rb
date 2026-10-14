require "test_helper"

class CsrfOriginTest < ActionDispatch::IntegrationTest
  setup do
    @original_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert ApplicationController.forgery_protection_origin_check
    host! "localhost:3000"
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @original_forgery_protection
  end

  test "document and recipient pages use a form compatible referrer policy" do
    document = create_document
    login(document.user)
    get document_path(document)
    assert_form_policy
    assert_select "form[action='#{send_for_signature_document_path(document)}'][method='post'][data-turbo='false']" do
      assert_select "input[name='authenticity_token'][value]", count: 1
    end
    get signing_path
    assert_form_policy
    assert_select "form[action='#{signing_access_path}'][method='post']" do
      assert_select "input[name='authenticity_token'][value]", count: 1
    end
  end

  [ "localhost:3000", "127.0.0.1:3000" ].each do |hostname|
    test "full form workflow with origin checks enabled on #{hostname}" do
      host! hostname
      origin = "http://#{hostname}"
      headers = { "Origin" => origin }
      get new_registration_path
      post registration_path, headers: headers, params: {
        authenticity_token: form_token(registration_path),
        user: { name: "Origin Owner", email: "origin@example.com", password: "secure-password-123",
          password_confirmation: "secure-password-123" }
      }
      assert_redirected_to new_session_path
      follow_redirect!
      post session_path, headers: headers, params: { authenticity_token: form_token(session_path),
        email: "origin@example.com", password: "secure-password-123" }
      assert_redirected_to dashboard_path
      get new_document_path
      post documents_path, headers: headers, params: { authenticity_token: form_token(documents_path),
        document: { title: "Origin contract", content: "Demo terms", recipient_name: "Recipient",
          recipient_email: "recipient@example.com", expires_at: 1.hour.from_now.iso8601 } }
      document = User.find_by!(email: "origin@example.com").documents.last
      assert_redirected_to document_path(document)
      follow_redirect!
      assert_form_policy
      post send_for_signature_document_path(document), headers: headers,
        params: { authenticity_token: form_token(send_for_signature_document_path(document)) }
      assert_response :success
      assert document.reload.pending?
      link = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
      assert_equal origin, "#{link.scheme}://#{link.host}:#{link.port}"
      assert_nil link.query
      token = URI.decode_www_form(link.fragment).to_h.fetch("token")

      recipient = open_session
      recipient.host! hostname
      recipient.get signing_path
      recipient.assert_equal "same-origin", recipient.response.headers["Referrer-Policy"]
      recipient.post signing_access_path, headers: headers,
        params: { token: token, authenticity_token: form_token(signing_access_path, client: recipient) }
      recipient.assert_redirected_to signing_path
      recipient.follow_redirect!
      recipient.assert_select ".contract-text", "Demo terms"
      recipient.assert_equal "same-origin", recipient.response.headers["Referrer-Policy"]
      signature_csrf = form_token(signing_path, client: recipient)
      signature_token = Nokogiri::HTML(recipient.response.body).at_css("form[action='/sign'] input[name='token']")["value"]
      recipient.assert_equal token, signature_token
      signature = { token: signature_token, authenticity_token: signature_csrf,
        signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
      recipient.post signing_path, headers: headers, params: signature
      recipient.assert_redirected_to signing_complete_path
      recipient.follow_redirect!
      recipient.assert_select "h1", "Demo imzanız kaydedildi."
      assert document.reload.signed?
      assert_equal "Recipient", document.signer_name
      assert document.signed_at
      get document_path(document)
      assert_select ".badge-signed", text: "İmzalandı"
      recipient.post signing_path, headers: headers, params: signature
      recipient.assert_response :not_found
    end
  end

  test "null foreign host and foreign port origins cannot dispatch even with a valid form token" do
    document = create_document
    login(document.user)
    get document_path(document)
    csrf = form_token(send_for_signature_document_path(document))
    [ "null", "http://127.0.0.1:3000", "http://localhost:3001", "https://foreign.example" ].each do |origin|
      post send_for_signature_document_path(document), headers: { "Origin" => origin },
        params: { authenticity_token: csrf }
      assert_response :unprocessable_entity
      assert document.reload.draft?
      assert_nil document.signing_token_digest
    end
  end

  test "same origin dispatch still rejects missing or invalid authenticity tokens" do
    document = create_document
    login(document.user)
    [ nil, "invalid" ].each do |csrf|
      post send_for_signature_document_path(document), headers: { "Origin" => "http://localhost:3000" },
        params: { authenticity_token: csrf }
      assert_response :unprocessable_entity
      assert document.reload.draft?
    end
  end

  test "Turbo style requests require a valid CSRF header and matching origin" do
    document = create_document
    login(document.user)
    get edit_document_path(document)
    csrf = Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
    headers = { "Origin" => "http://localhost:3000", "X-CSRF-Token" => csrf,
      "Accept" => "text/vnd.turbo-stream.html, text/html" }
    patch document_path(document), headers: headers, params: { document: { title: "Updated via Turbo" } }
    assert_redirected_to document_path(document)
    assert_equal "Updated via Turbo", document.reload.title
    [ headers.except("X-CSRF-Token"), headers.merge("Origin" => "http://127.0.0.1:3000") ].each do |invalid_headers|
      patch document_path(document), headers: invalid_headers, params: { document: { title: "Invalid update" } }
      assert_response :unprocessable_entity
      assert_equal "Updated via Turbo", document.reload.title
    end
  end

  test "recipient exchange and signature reject null origin even with valid tokens" do
    document = create_document
    token = document.send_for_signature!
    get signing_path
    exchange_csrf = form_token(signing_access_path)
    post signing_access_path, headers: { "Origin" => "null" },
      params: { token: token, authenticity_token: exchange_csrf }
    assert_response :unprocessable_entity
    post signing_access_path, headers: { "Origin" => "http://localhost:3000" },
      params: { token: token, authenticity_token: exchange_csrf }
    assert_redirected_to signing_path
    follow_redirect!
    post signing_path, headers: { "Origin" => "null" }, params: { token: token,
      authenticity_token: form_token(signing_path), signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
    assert_response :unprocessable_entity
    assert document.reload.pending?
    assert_nil document.signed_at
  end

  test "localhost and loopback IP do not share an authenticated cookie session" do
    login(create_user)
    get dashboard_path
    assert_response :success
    host! "127.0.0.1:3000"
    get dashboard_path
    assert_redirected_to new_session_path
  end

  private

  def login(user)
    get new_session_path
    post session_path, headers: { "Origin" => "http://localhost:3000" },
      params: { email: user.email, password: "secure-password-123", authenticity_token: form_token(session_path) }
    assert_redirected_to dashboard_path
  end

  def form_token(action, client: self)
    field = Nokogiri::HTML(client.response.body).at_css("form[action='#{action}'] input[name='authenticity_token']")
    client.assert field, "Expected Rails to embed an authenticity token in #{action}"
    client.assert field["value"].present?
    field["value"]
  end

  def assert_form_policy
    assert_select "meta[name='referrer'][content='no-referrer']", count: 0
    assert_equal "same-origin", response.headers["Referrer-Policy"]
  end
end
