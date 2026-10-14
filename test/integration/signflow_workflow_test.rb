require "test_helper"
require "stringio"

class SignflowWorkflowTest < ActionDispatch::IntegrationTest
  test "registration login document dispatch recipient signature and owner confirmation" do
    get root_path
    assert_response :success
    get new_registration_path
    assert_response :success
    assert_difference "User.count", 1 do
      post registration_path, params: { user: { name: "Owner", email: "new@example.com",
        password: "secure-password-123", password_confirmation: "secure-password-123" } }
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "h1", "Tekrar hoş geldiniz."
    post session_path, params: { email: "new@example.com", password: "secure-password-123" }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select "h1", /Merhaba/
    get new_document_path
    assert_response :success
    assert_difference "Document.count", 1 do
      post documents_path, params: { document: { title: "Demo consulting agreement",
        content: "Agreed service terms.", recipient_name: "Deniz", recipient_email: "deniz@example.com",
        expires_at: 1.day.from_now.iso8601, status: "signed", user_id: -1 } }
    end
    document = User.find_by!(email: "new@example.com").documents.last
    assert document.draft?
    assert_redirected_to document_path(document)
    get edit_document_path(document)
    assert_response :success
    patch document_path(document), params: { document: { content: "Updated terms." } }
    assert_redirected_to document_path(document)
    assert_equal "Updated terms.", document.reload.content

    post send_for_signature_document_path(document)
    assert_response :success
    link = Nokogiri::HTML(response.body).at_css("#signing-link")["value"]
    uri = URI.parse(link)
    assert_nil uri.query
    token = URI.decode_www_form(uri.fragment).to_h.fetch("token")
    assert_equal Document.token_digest(token), document.reload.signing_token_digest
    assert document.pending?
    assert_equal "no-store", response.headers["Cache-Control"]

    recipient = open_session
    recipient.get signing_path
    assert_response :success
    recipient.post signing_access_path, params: { token: token, document_id: -1 }
    recipient.assert_redirected_to signing_path
    recipient.follow_redirect!
    recipient.assert_select ".contract-text", "Updated terms."
    assert_equal "same-origin", recipient.response.headers["Referrer-Policy"]
    recipient.post signing_path, params: { token: token, signature_acceptance: { signer_name: "  Deniz Yılmaz  ", accepted: "1" } }
    recipient.assert_redirected_to signing_complete_path
    recipient.follow_redirect!
    recipient.assert_select "h1", "Demo imzanız kaydedildi."
    assert document.reload.signed?
    assert_equal "Deniz Yılmaz", document.signer_name
    assert document.signed_at
    assert_nil document.signing_token_digest
    get document_path(document)
    assert_select ".badge-signed", text: "İmzalandı"
    assert_includes response.body, "Deniz Yılmaz"
    get dashboard_path
    assert_response :success
    assert_select ".badge-signed", text: "İmzalandı"
    recipient.post signing_access_path, params: { token: token }
    recipient.assert_response :not_found
    recipient.post signing_path, params: { token: token, signature_acceptance: { signer_name: "Again", accepted: "1" } }
    recipient.assert_response :not_found
  end

  test "owner routes require authentication and hide other users documents" do
    document = create_document
    get documents_path
    assert_redirected_to new_session_path
    other = create_user(email: "other@example.com")
    login(other)
    [ document_path(document), edit_document_path(document) ].each do |path|
      get path
      assert_response :not_found
      assert_not_includes response.body, document.content
    end
    patch document_path(document), params: { document: { title: "Stolen" } }
    assert_response :not_found
    post send_for_signature_document_path(document)
    assert_response :not_found
    assert document.reload.draft?
    get documents_path
    assert_not_includes response.body, document.title
  end

  test "sent terms cannot be modified through HTTP" do
    document = create_document
    document.send_for_signature!
    login(document.user)
    get edit_document_path(document)
    assert_redirected_to document_path(document)
    patch document_path(document), params: { document: { title: "Changed", content: "Changed" } }
    assert_response :unprocessable_entity
    assert_equal "Demo contract", document.reload.title
    post send_for_signature_document_path(document)
    assert_response :unprocessable_entity
    assert document.reload.pending?
  end

  test "invalid registration and invalid drafts render errors without persisting" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: { name: "", email: "invalid", password: "short" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    login(create_user)
    assert_no_difference "Document.count" do
      post documents_path, params: { document: { title: "", content: "" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]"
  end

  test "incomplete draft cannot be sent and link is not exposed on subsequent detail requests" do
    document = create_document
    document.update!(recipient_name: nil)
    login(document.user)
    post send_for_signature_document_path(document)
    assert_response :unprocessable_entity
    assert document.reload.draft?
    document.update!(recipient_name: "Recipient")
    post send_for_signature_document_path(document)
    assert_select "#signing-link", count: 1
    get document_path(document)
    assert_select "#signing-link", count: 0
  end

  test "requires both explicit acceptance and a nonblank signer name" do
    document = create_document
    token = document.send_for_signature!
    post signing_access_path, params: { token: token }
    [ { signer_name: "Deniz", accepted: "0" }, { signer_name: "  ", accepted: "1" },
      { signer_name: "a" * 121, accepted: "1" } ].each do |signature|
      post signing_path, params: { token: token, signature_acceptance: signature }
      assert_response :unprocessable_entity
      assert_select "[role=alert]"
      assert document.reload.pending?
      assert_nil document.signed_at
      assert_nil document.signer_name
    end
  end

  test "signing scope ignores document IDs and never exposes another document" do
    first = create_document
    second = create_document(user: first.user)
    second.update!(title: "Private other contract", content: "Other confidential terms")
    token = first.send_for_signature!
    second.send_for_signature!
    post signing_access_path, params: { token: token, document_id: second.id }
    follow_redirect!
    assert_select ".contract-text", first.content
    assert_not_includes response.body, second.content
    post signing_path, params: { token: token, document_id: second.id,
      signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
    assert first.reload.signed?
    assert second.reload.pending?
  end

  test "deadline between viewing and signing denies signature and persists expiration" do
    document = create_document
    document.update!(expires_at: 1.hour.from_now)
    token = document.send_for_signature!
    post signing_access_path, params: { token: token }
    follow_redirect!
    assert_response :success
    travel_to document.expires_at, with_usec: true do
      post signing_path, params: { token: token, signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
      assert_response :not_found
      assert document.reload.expired?
      assert_nil document.signer_name
      assert_nil document.signing_token_digest
    end
  end

  test "dashboard persists expired status and lists it accurately" do
    document = create_document
    document.update!(expires_at: 1.hour.from_now)
    document.send_for_signature!
    login(document.user)
    travel_to document.expires_at, with_usec: true do
      get dashboard_path
      assert_response :success
      assert document.reload.expired?
      assert_select ".badge-expired", text: "Süresi doldu"
      get documents_path(status: "expired")
      assert_response :success
      assert_select ".badge-expired", text: "Süresi doldu"
    end
  end

  test "contract content and signer names are escaped" do
    document = create_document
    document.update!(content: '<script id="attack">alert(1)</script>')
    token = document.send_for_signature!
    post signing_access_path, params: { token: token }
    follow_redirect!
    assert_select "script#attack", count: 0
    assert_includes response.body, "&lt;script"
    post signing_path, params: { token: token, signature_acceptance: { signer_name: '<img id="attack" src=x>', accepted: "1" } }
    login(document.user)
    get document_path(document)
    assert_select "img#attack", count: 0
    assert_includes response.body, "&lt;img"
  end

  test "CSRF protected HTML workflow can register login dispatch and sign" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    get new_registration_path
    post registration_path, params: { authenticity_token: csrf_token,
      user: { name: "CSRF Owner", email: "csrf@example.com", password: "secure-password-123",
        password_confirmation: "secure-password-123" } }
    assert_redirected_to new_session_path
    follow_redirect!
    post session_path, params: { authenticity_token: csrf_token,
      email: "csrf@example.com", password: "secure-password-123" }
    follow_redirect!
    document = create_document(user: User.find_by!(email: "csrf@example.com"))
    post send_for_signature_document_path(document), params: { authenticity_token: csrf_token }
    token = URI.decode_www_form(URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"]).fragment).to_h.fetch("token")
    recipient = open_session
    recipient.get signing_path
    recipient_token = Nokogiri::HTML(recipient.response.body).at_css('meta[name="csrf-token"]')["content"]
    recipient.post signing_access_path, params: { token: token, authenticity_token: recipient_token }
    recipient.follow_redirect!
    recipient_token = Nokogiri::HTML(recipient.response.body).at_css('meta[name="csrf-token"]')["content"]
    recipient.post signing_path, params: { token: token, authenticity_token: recipient_token,
      signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
    recipient.assert_redirected_to signing_complete_path
    assert document.reload.signed?
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "CSRF protection rejects token exchange and signing without authenticity token" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    document = create_document
    token = document.send_for_signature!
    post signing_access_path, params: { token: token }
    assert_response :unprocessable_entity
    post signing_path, params: { signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
    assert_response :unprocessable_entity
    assert document.reload.pending?
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "raw token is filtered from request logs" do
    document = create_document
    token = document.send_for_signature!
    output = StringIO.new
    capture = ActiveSupport::Logger.new(output)
    Rails.logger.broadcast_to(capture)
    post signing_access_path, params: { token: token }
    assert_redirected_to signing_path
    assert_not_includes output.string, token
    assert_includes output.string, "[FILTERED]"
    post signing_path, params: { token: token, signature_acceptance: { signer_name: "Recipient", accepted: "1" } }
    assert_redirected_to signing_complete_path
    assert_not_includes output.string, token
  ensure
    Rails.logger.stop_broadcasting_to(capture) if capture
  end

  test "two links opened in one browser sign the document shown by each form" do
    first = create_document
    second = create_document(user: first.user)
    first_token = first.send_for_signature!
    second_token = second.send_for_signature!
    post signing_access_path, params: { token: first_token }
    follow_redirect!
    first_form_token = Nokogiri::HTML(response.body).at_css('form[action="/sign"] input[name="token"]')["value"]
    post signing_access_path, params: { token: second_token }
    post signing_path, params: { token: first_form_token,
      signature_acceptance: { signer_name: "First signer", accepted: "1" } }
    assert first.reload.signed?
    assert second.reload.pending?
    assert_equal first_token, first_form_token
  end

  private

  def login(user)
    post session_path, params: { email: user.email, password: "secure-password-123" }
    assert_redirected_to dashboard_path
  end

  def csrf_token
    Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')["content"]
  end
end
