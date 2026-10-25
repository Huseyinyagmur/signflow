require "test_helper"
require "active_support/testing/constant_stubbing"

class NewUserTemplatesTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::ConstantStubbing
  TITLES = [ "Yazılım Geliştirme Hizmet Sözleşmesi", "Gizlilik Sözleşmesi", "Danışmanlık Hizmet Sözleşmesi" ].freeze

  setup do
    @flag = ENV["AI_CONTRACTS_ENABLED"]
    ENV["AI_CONTRACTS_ENABLED"] = "true"
    @csrf = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @origin = { "Origin" => "http://www.example.com" }
  end

  teardown do
    ENV["AI_CONTRACTS_ENABLED"] = @flag
    ActionController::Base.allow_forgery_protection = @csrf
    AiContracts::Conversations.reset!
  end

  test "registration provisions three own versioned templates and can start AI without a model call" do
    assert_difference("User.count", 1) do
      assert_difference([ "Template.count", "TemplateVersion.count" ], 3) { register("new-ai@example.com") }
    end
    assert_redirected_to new_session_path
    owner = User.find_by!(email: "new-ai@example.com")
    assert_equal TITLES.sort, owner.templates.includes(:current_version).map(&:title).sort
    assert owner.templates.all? { |template| template.current_version.number == 1 }
    login(owner)
    get templates_path
    TITLES.each { |title| assert_select "main", text: /#{Regexp.escape(title)}/ }
    get new_ai_contract_path
    owner.templates.each { |template| assert_select "option[value='#{template.current_version_id}']" }
    version = owner.templates.find_by!(seed_key: "software").current_version
    assert_no_difference("Document.count") do
      assert_difference("AiContractConversation.count", 1) do
        post ai_contracts_path, headers: @origin, params: { authenticity_token: csrf, template_version_id: version.id, synthetic: "1" }
      end
    end
    conversation = owner.ai_contract_conversations.last
    assert_redirected_to ai_contract_path(conversation)
    assert_equal version.id, conversation.template_version_id
    follow_redirect!
    assert_response :success
  end

  test "starter sets belong to different users and foreign versions remain forbidden" do
    register("first-ai@example.com")
    first = User.find_by!(email: "first-ai@example.com")
    register("second-ai@example.com")
    second = User.find_by!(email: "second-ai@example.com")
    assert_equal 3, first.templates.count
    assert_equal 3, second.templates.count
    assert_empty first.templates.pluck(:current_version_id) & second.templates.pluck(:current_version_id)
    foreign = first.templates.find_by!(seed_key: "software")
    login(second)
    get new_ai_contract_path
    assert_select "option[value='#{foreign.current_version_id}']", count: 0
    assert_no_difference([ "AiContractConversation.count", "Document.count" ]) do
      post ai_contracts_path, headers: @origin, params: { authenticity_token: csrf, template_version_id: foreign.current_version_id, synthetic: "1" }
      assert_response :not_found
    end
  end

  test "template failure rolls back the user and the entire starter set with a safe registration error" do
    examples = [ Templates::DemoSeeder::EXAMPLES.first, Templates::DemoSeeder::EXAMPLES.second.merge(title: "") ]
    stub_const(Templates::DemoSeeder, :EXAMPLES, examples) do
      assert_no_difference([ "User.count", "Template.count", "TemplateVersion.count" ]) { register("failed-ai@example.com") }
      assert_response :unprocessable_entity
      assert_select "[role='alert']", text: /Başlangıç şablonları/
      assert_select "form[action='#{registration_path}']"
      assert_nil User.find_by(email: "failed-ai@example.com")
    end
    register("failed-ai@example.com")
    assert_redirected_to new_session_path
    assert_equal 3, User.find_by!(email: "failed-ai@example.com").templates.count
  end

  test "legacy empty account has explicit CSRF protected opt in recovery and repeat is a no op" do
    legacy = create_user
    login(legacy)
    assert_no_difference([ "Template.count", "TemplateVersion.count" ]) { get new_ai_contract_path }
    assert_response :success
    assert_select "[data-empty-templates]", text: /şablon/
    assert_select "form[action='#{prepare_templates_ai_contracts_path}'] input[name='authenticity_token']"
    assert_select "form[action='#{ai_contracts_path}']", count: 0
    assert_difference([ "Template.count", "TemplateVersion.count" ], 3) { prepare }
    assert_redirected_to new_ai_contract_path
    follow_redirect!
    assert_select "option", count: 3
    before = legacy.templates.includes(:versions).map { |template| [ template.attributes, template.versions.map(&:attributes) ] }
    assert_no_difference([ "Template.count", "TemplateVersion.count" ]) { prepare }
    assert_equal before, legacy.templates.reload.includes(:versions).map { |template| [ template.attributes, template.versions.map(&:attributes) ] }
  end

  test "existing templates stay unchanged on visits and recovery failure leaves no partial set" do
    owner = create_user
    custom = create_template(user: owner)
    snapshot = [ custom.attributes, custom.current_version.attributes ]
    login(owner)
    assert_no_difference([ "Template.count", "TemplateVersion.count" ]) { get new_ai_contract_path }
    assert_select "option", count: 1
    examples = [ Templates::DemoSeeder::EXAMPLES.first, Templates::DemoSeeder::EXAMPLES.second.merge(title: "") ]
    stub_const(Templates::DemoSeeder, :EXAMPLES, examples) do
      assert_no_difference([ "Template.count", "TemplateVersion.count" ]) { prepare }
      assert_response :unprocessable_entity
      assert_select "[role='alert']", text: /Başlangıç şablonları eklenemedi/
      assert_select "[role='status']", count: 0
    end
    assert_equal snapshot, [ custom.reload.attributes, custom.current_version.reload.attributes ]
    get new_ai_contract_path
    assert_difference([ "Template.count", "TemplateVersion.count" ], 3) { prepare }
    assert_equal snapshot, [ custom.reload.attributes, custom.current_version.reload.attributes ]
  end

  test "recovery requires authentication CSRF and same origin and ignores supplied owner" do
    owner = create_user
    other = create_user(email: "other-ai@example.com")
    get root_path
    post prepare_templates_ai_contracts_path, headers: @origin, params: { authenticity_token: csrf }
    assert_redirected_to new_session_path
    login(owner)
    get new_ai_contract_path
    csrf_token = csrf
    assert_no_difference([ "Template.count", "TemplateVersion.count" ]) do
      post prepare_templates_ai_contracts_path, headers: @origin
      assert_response :unprocessable_entity
      post prepare_templates_ai_contracts_path, headers: { "Origin" => "https://evil.example" }, params: { authenticity_token: csrf_token }
      assert_response :unprocessable_entity
    end
    get new_ai_contract_path
    post prepare_templates_ai_contracts_path, headers: @origin, params: { authenticity_token: csrf, user_id: other.id }
    assert_redirected_to new_ai_contract_path
    assert_equal 3, owner.templates.count
    assert_equal 0, other.templates.count
    ENV["AI_CONTRACTS_ENABLED"] = "false"
    get new_ai_contract_path
    assert_response :not_found
  end

  test "an incomplete legacy starter is not overwritten or reported as ready" do
    owner = create_user
    incomplete = owner.templates.create!(seed_key: "software")
    snapshot = incomplete.attributes
    login(owner)
    get new_ai_contract_path
    assert_select "[data-empty-templates]"
    assert_no_difference([ "User.count", "Template.count", "TemplateVersion.count" ]) { prepare }
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Başlangıç şablonları eklenemedi/
    assert_select "[role='status']", count: 0
    assert_equal snapshot, incomplete.reload.attributes
  end

  private

  def register(email)
    get new_registration_path
    post registration_path, headers: @origin, params: { authenticity_token: csrf,
      user: { name: "Synthetic Demo", email: email, password: "secure-password-123", password_confirmation: "secure-password-123" } }
  end

  def login(owner)
    get new_session_path
    post session_path, headers: @origin, params: { authenticity_token: csrf, email: owner.email, password: "secure-password-123" }
    assert_redirected_to dashboard_path
  end

  def prepare
    post prepare_templates_ai_contracts_path, headers: @origin, params: { authenticity_token: csrf }
  end

  def csrf
    Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
  end
end
