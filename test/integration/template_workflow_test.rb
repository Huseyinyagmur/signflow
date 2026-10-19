require "test_helper"
require "active_support/testing/constant_stubbing"

class TemplateWorkflowTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::ConstantStubbing

  setup do
    @owner = create_user
    @manager = Templates::Manage.new(user: @owner)
    login(@owner)
  end

  test "owner creates edits searches and browses version history" do
    get new_template_path
    assert_response :success
    assert_difference [ "Template.count", "TemplateVersion.count" ], 1 do
      post templates_path, params: { template_revision: {
        title: "Consulting", description: "Monthly services", content: "{{alici_adi}}: {{hizmet}}", user_id: -1 } }
    end
    template = @owner.templates.last
    first_version = template.current_version
    assert_redirected_to template_path(template)
    follow_redirect!
    assert_select "h1", "Consulting"
    assert_equal @owner, template.user
    get edit_template_path(template)
    assert_response :success
    assert_difference "TemplateVersion.count", 1 do
      patch template_path(template), params: { template_revision: {
        title: "New consulting", description: "Updated description", content: "{{alici_adi}}: {{hizmet}} / {{ucret}}" } }
    end
    assert_redirected_to template_path(template)
    assert_equal 2, template.reload.current_version.number
    get templates_path(q: "Updated")
    assert_select "h2", "New consulting"
    get templates_path(q: "%")
    assert_select "h2", "Aramanızla eşleşen şablon yok."
    get history_template_path(template)
    assert_response :success
    assert_select "article", count: 2
    get template_path(template, version_id: first_version.id)
    assert_select ".contract-text", "{{alici_adi}}: {{hizmet}}"
    assert_select "h1", "Consulting"
  end

  test "invalid templates return validation errors without partial writes" do
    assert_no_difference [ "Template.count", "TemplateVersion.count" ] do
      post templates_path, params: { template_revision: { title: "", content: "{{unknown}}" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    template = create_template(user: @owner)
    assert_no_difference "TemplateVersion.count" do
      patch template_path(template), params: { template_revision: { title: "Bad", content: "{{unfinished" } }
    end
    assert_response :unprocessable_entity
    assert_equal 1, template.reload.current_version.number
  end

  test "unknown missing blank and nested values prevent preview and creation" do
    template = create_template(user: @owner, content: "{{hizmet}}")
    [ {}, { "hizmet" => " " }, { "hizmet" => "Valid", "unknown" => "X" },
      { "hizmet" => { "nested" => "not text" } } ].each do |values|
      params = generation_params(template, values: values)
      assert_no_difference "Document.count" do
        post preview_template_documents_path(template), params: params
        assert_response :unprocessable_entity
        assert_select "[role=alert]"
        post template_documents_path(template), params: params
        assert_response :unprocessable_entity
        assert_select "[role=alert]"
      end
    end
  end

  test "preview renders escaped data without executing ERB and creation ignores supplied content" do
    template = create_template(user: @owner, content: '<%= raise "executed" %> {{hizmet}}')
    attack = '<script id="attack">alert(1)</script>'
    params = generation_params(template, values: { "hizmet" => attack })
    params[:document][:content] = "Untrusted preview text"
    post preview_template_documents_path(template), params: params
    assert_response :success
    assert_select "script#attack", count: 0
    assert_includes response.body, "&lt;script"
    assert_includes response.body, "&lt;%="
    assert_select "#template-preview .contract-text", text: "<%= raise \"executed\" %> #{attack}"
    post template_documents_path(template), params: params
    document = @owner.documents.last
    assert_redirected_to document_path(document)
    assert_equal "<%= raise \"executed\" %> #{attack}", document.content
  end

  test "selected version is pinned even when template changes after opening the form" do
    template = create_template(user: @owner, content: "Old {{hizmet}}")
    version = template.current_version
    get new_template_document_path(template)
    assert_select "input[name='version_id'][value='#{version.id}']", count: 1
    @manager.update!(template.id, title: "New template", content: "New {{ucret}}")
    post template_documents_path(template), params: generation_params(template, version: version, values: { "hizmet" => "Service" })
    assert_redirected_to document_path(@owner.documents.last)
    assert_equal "Old Service", @owner.documents.last.content
    assert_equal version.id, @owner.documents.last.template_version_id
    assert_equal 2, template.reload.current_version.number
  end

  test "other users cannot read edit preview create from or enumerate versions of a template" do
    template = create_template(user: create_user(email: "other@example.com"))
    [ template_path(template), edit_template_path(template), history_template_path(template),
      new_template_document_path(template) ].each do |path|
      get path
      assert_response :not_found
      assert_not_includes response.body, template.content
    end
    patch template_path(template), params: { template_revision: { title: "Stolen", content: "Changed" } }
    assert_response :not_found
    [ preview_template_documents_path(template), template_documents_path(template) ].each do |path|
      post path, params: generation_params(template)
      assert_response :not_found
    end
    get templates_path
    assert_not_includes response.body, template.title
    own_template = create_template(user: @owner)
    get template_path(own_template, version_id: template.current_version_id)
    assert_response :not_found
    post template_documents_path(own_template), params: generation_params(own_template, version: template.current_version)
    assert_response :not_found
  end

  test "demo action is idempotent and scoped to logged in user" do
    assert_difference [ "Template.count", "TemplateVersion.count" ], 3 do
      post add_examples_templates_path
    end
    assert_redirected_to templates_path
    assert_equal "3 demo şablonu eklendi. Mevcut şablonlarınız korunuyor.", flash[:notice]
    assert_equal 3, @owner.templates.count
    seeded = @owner.templates.find_by!(seed_key: "software")
    @manager.update!(seeded.id, title: "My edited sample", content: "My custom text")
    versions = seeded.versions.order(:number).pluck(:id, :number, :title, :content)
    assert_no_difference [ "Template.count", "TemplateVersion.count" ] do
      post add_examples_templates_path
    end
    assert_equal "Tüm demo şablonları zaten mevcut. Herhangi bir değişiklik yapılmadı.", flash[:notice]
    assert_equal versions, seeded.versions.order(:number).pluck(:id, :number, :title, :content)
    assert_equal "My custom text", seeded.reload.content
    get templates_path
    assert_select "article", count: 3
  end

  test "demo action reports only missing examples and preserves existing versions" do
    example = Templates::DemoSeeder::EXAMPLES.first
    existing = @manager.create!(example.except(:key), seed_key: example.fetch(:key))
    @manager.update!(existing.id, title: "Edited demo", content: "Custom content")
    versions = existing.versions.order(:number).pluck(:id, :number, :title, :content)

    assert_difference [ "Template.count", "TemplateVersion.count" ], 2 do
      post add_examples_templates_path
    end
    assert_redirected_to templates_path
    assert_equal "2 demo şablonu eklendi. Mevcut şablonlarınız korunuyor.", flash[:notice]
    assert_equal versions, existing.versions.order(:number).pluck(:id, :number, :title, :content)
    assert_equal "Custom content", existing.reload.content
    assert_equal 3, @owner.templates.count
  end

  test "demo seeding failure does not announce success" do
    get templates_path
    assert_response :success
    previous_notice = flash[:notice]
    examples = [ Templates::DemoSeeder::EXAMPLES.first,
      Templates::DemoSeeder::EXAMPLES.second.merge(title: "") ]
    stub_const(Templates::DemoSeeder, :EXAMPLES, examples) do
      assert_no_difference [ "Template.count", "TemplateVersion.count" ] do
        assert_raises(ActiveModel::ValidationError) { post add_examples_templates_path }
      end
    end
    assert_equal previous_notice, flash[:notice]
  end

  test "template routes require login" do
    delete session_path
    [ templates_path, new_template_path ].each do |path|
      get path
      assert_redirected_to new_session_path
    end
    post templates_path, params: { template_revision: { title: "Unauthorized", content: "Text" } }
    assert_redirected_to new_session_path
  end

  test "template generation form preserves errors and exposes only detected fields" do
    template = create_template(user: @owner, content: "{{hizmet}} {{hizmet}} {{ucret}}")
    get new_template_document_path(template)
    assert_select "input[name='values[hizmet]']", count: 1
    assert_select "input[name='values[ucret]']", count: 1
    assert_select "input[name='values[alici_adi]']", count: 0
    params = generation_params(template, values: { "hizmet" => "Consulting", "ucret" => "100 TRY" })
    params[:document][:recipient_email] = "invalid"
    post preview_template_documents_path(template), params: params
    assert_response :unprocessable_entity
    assert_select "input[name='values[hizmet]'][value='Consulting']", count: 1
    assert_select "[role=alert]"
  end

  test "CSRF and same-origin protected template to signed workflow keeps independent snapshots" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert ApplicationController.forgery_protection_origin_check
    headers = { "Origin" => "http://www.example.com" }
    get new_template_path
    post templates_path, headers: headers, params: { authenticity_token: form_token(templates_path),
      template_revision: { title: "Workflow template", description: "Demo", content: "{{alici_adi}}: {{hizmet}} / {{ucret}}" } }
    assert_redirected_to template_path(@owner.templates.last)
    template = @owner.templates.last
    get new_template_document_path(template)
    assert_equal "same-origin", response.headers["Referrer-Policy"]
    csrf = form_token(template_documents_path(template))
    params = generation_params(template).merge(authenticity_token: csrf)
    post preview_template_documents_path(template), headers: headers, params: params
    assert_response :success
    assert_select "#template-preview .contract-text", "Deniz: Development / 100 TRY"
    assert_no_difference "Document.count" do
      post template_documents_path(template), headers: headers, params: params.except(:authenticity_token)
      assert_response :unprocessable_entity
    end
    post template_documents_path(template), headers: headers, params: params
    document = @owner.documents.last
    assert_redirected_to document_path(document)
    assert document.draft?
    snapshot = document.content
    source_id = document.template_version_id
    follow_redirect!
    csrf = form_token(send_for_signature_document_path(document))
    post send_for_signature_document_path(document), headers: headers, params: { authenticity_token: csrf }
    assert_response :success
    link = URI.parse(Nokogiri::HTML(response.body).at_css("#signing-link")["value"])
    token = URI.decode_www_form(link.fragment).to_h.fetch("token")
    @manager.update!(template.id, title: "Updated template", content: "Changed {{hizmet}}")
    assert_equal snapshot, document.reload.content
    recipient = open_session
    recipient.get signing_path
    csrf = form_token(signing_access_path, client: recipient)
    recipient.post signing_access_path, headers: headers, params: { token: token, authenticity_token: csrf }
    recipient.assert_redirected_to signing_path
    recipient.follow_redirect!
    recipient.assert_select ".contract-text", snapshot
    csrf = form_token(signing_path, client: recipient)
    recipient.post signing_path, headers: headers, params: { token: token, authenticity_token: csrf,
      signature_acceptance: { signer_name: "Deniz", accepted: "1" } }
    recipient.assert_redirected_to signing_complete_path
    assert document.reload.signed?
    assert_equal source_id, document.template_version_id
    @manager.update!(template.id, title: "Third template", content: "Other {{hizmet}}")
    assert_equal snapshot, document.reload.content
    recipient.post signing_path, headers: headers, params: { token: token, authenticity_token: csrf,
      signature_acceptance: { signer_name: "Deniz", accepted: "1" } }
    recipient.assert_response :not_found
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  private

  def login(user)
    post session_path, params: { email: user.email, password: "secure-password-123" }
    assert_redirected_to dashboard_path
  end

  def generation_params(template, version: template.current_version, values: nil)
    values ||= { "alici_adi" => "Deniz", "hizmet" => "Development", "ucret" => "100 TRY" }
    { version_id: version.id, values: values,
      document: { title: "Generated contract", recipient_email: "recipient@example.com", expires_at: 1.hour.from_now.iso8601 } }
  end

  def form_token(action, client: self)
    field = Nokogiri::HTML(client.response.body).at_css("form[action='#{action}'] input[name='authenticity_token']")
    client.assert field, "Missing authenticity_token for #{action}"
    field["value"]
  end
end
