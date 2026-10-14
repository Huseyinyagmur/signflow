require "test_helper"

class TemplateSchemaRegressionTest < ActionDispatch::IntegrationTest
  test "physical database has a nullable indexed foreign key matching the optional model association" do
    connection = ActiveRecord::Base.connection
    # Read the actual SQLite catalog, not schema.rb or mocked model metadata.
    column = connection.select_all("PRAGMA table_info(documents)").find { |entry| entry["name"] == "template_version_id" }
    assert column, "Run pending migrations: documents.template_version_id is missing from the real database"
    assert_equal 0, column["notnull"]
    assert connection.indexes(:documents).any? { |entry| entry.columns == [ "template_version_id" ] }
    foreign_keys = connection.select_all("PRAGMA foreign_key_list(documents)")
    assert foreign_keys.any? { |entry| entry["from"] == "template_version_id" && entry["table"] == "template_versions" }
    assert Document.column_names.include?("template_version_id"), "Model metadata is stale; restart the Rails process after migration"
    assert Document.reflect_on_association(:template_version).options[:optional]
    assert_equal "template_version_id", Document.reflect_on_association(:template_version).foreign_key
  end

  test "preview writes no records then persists its source and completes the signed flow" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert ApplicationController.forgery_protection_origin_check
    owner = create_user
    template = create_template(user: owner, content: "{{alici_adi}} / {{hizmet}}")
    version = template.current_version
    headers = { "Origin" => "http://www.example.com" }
    get new_session_path
    post session_path, headers: headers, params: { email: owner.email, password: "secure-password-123",
      authenticity_token: form_token(session_path) }
    assert_redirected_to dashboard_path
    get new_template_document_path(template)
    params = { version_id: version.id, authenticity_token: form_token(template_documents_path(template)),
      values: { alici_adi: "Deniz", hizmet: "Development" },
      document: { title: "Schema regression", recipient_email: "recipient@example.com", expires_at: 1.hour.from_now.iso8601 } }

    assert_no_difference [ "User.count", "Document.count", "Template.count", "TemplateVersion.count" ] do
      post preview_template_documents_path(template), headers: headers, params: params
      assert_response :success
      assert_select "#template-preview .contract-text", "Deniz / Development"
    end
    assert_difference "Document.count", 1 do
      post template_documents_path(template), headers: headers, params: params
    end
    document = owner.documents.order(:id).last
    assert_redirected_to document_path(document)
    # Verify the value from a new SQL query, not just the in-memory association.
    assert_equal version.id, Document.where(id: document.id).pick(:template_version_id)
    assert_equal version.id, document.reload.template_version.id
    assert_equal "Deniz / Development", document.content
    assert document.draft?
    follow_redirect!
    post send_for_signature_document_path(document), headers: headers,
      params: { authenticity_token: form_token(send_for_signature_document_path(document)) }
    assert_response :success
    uri = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
    token = URI.decode_www_form(uri.fragment).to_h.fetch("token")
    recipient = open_session
    recipient.get signing_path
    recipient.post signing_access_path, headers: headers, params: { token: token,
      authenticity_token: form_token(signing_access_path, client: recipient) }
    recipient.assert_redirected_to signing_path
    recipient.follow_redirect!
    recipient.assert_select ".contract-text", "Deniz / Development"
    recipient.post signing_path, headers: headers, params: { token: token,
      authenticity_token: form_token(signing_path, client: recipient),
      signature_acceptance: { signer_name: "Deniz", accepted: "1" } }
    recipient.assert_redirected_to signing_complete_path
    assert document.reload.signed?
    assert_equal version.id, document.template_version_id
    assert_equal "Deniz", document.signer_name
    assert document.signed_at
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "legacy documents without a template still display and sign normally" do
    document = create_document
    assert_nil document.reload.template_version_id
    assert_nil document.template_version
    assert document.valid?
    post session_path, params: { email: document.user.email, password: "secure-password-123" }
    get document_path(document)
    assert_response :success
    post send_for_signature_document_path(document)
    assert_response :success
    uri = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
    token = URI.decode_www_form(uri.fragment).to_h.fetch("token")
    Documents::Signing.sign!(token: token, signer_name: "Recipient", accepted: "1")
    assert document.reload.signed?
    assert_nil document.template_version_id
  end

  private

  def form_token(action, client: self)
    field = Nokogiri::HTML(client.response.body).at_css("form[action='#{action}'] input[name='authenticity_token']")
    client.assert field, "Missing CSRF token in #{action}"
    field["value"]
  end
end
