require "test_helper"

class AiContractsServiceTest < ActiveSupport::TestCase
  setup do
    AiContracts::Conversations.reset!
    @user = create_user
    @template = create_template(user: @user, content: "{{hizmet}}")
    @service = AiContracts::Conversations.new(user: @user)
    @conversation = @service.start(version_id: @template.current_version_id, synthetic: "1")
  end

  teardown { AiContracts::Conversations.reset! }

  test "version remains pinned and database stores no chat prompts or payload" do
    old = @template.current_version_id
    Templates::Manage.new(user: @user).update!(@template.id, { title: "New revision", content: "Changed {{hizmet}}" })
    assert_equal old, @conversation.reload.template_version_id
    assert_empty AiContractConversation.column_names & %w[prompt messages payload api_key token]
    assert ActiveRecord::Base.connection.indexes(:ai_contract_conversations).any? { |index| index.unique && index.columns == [ "document_id" ] }
    assert ActiveRecord::Base.connection.foreign_keys(:ai_contract_conversations).any? { |key| key.to_table == "template_versions" }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { @conversation.update!(template_version_id: @template.reload.current_version_id) }
  end

  test "TTL is exact and lost memory cannot silently restart a billed request" do
    travel_to @conversation.expires_at, with_usec: true do
      assert_equal "conversation_expired", assert_raises(SignflowAgent::Error) { @service.snapshot(@conversation) }.message
      assert_no_difference("Document.count") { assert_raises(SignflowAgent::Error) { @service.approve(@conversation) } }
    end
    AiContracts::Conversations.reset!
    assert_equal "conversation_lost_start_new", assert_raises(SignflowAgent::Error) { @service.snapshot(@conversation) }.message
  end

  test "per user quota counts failures and expires without affecting another user" do
    travel_to Time.current.change(sec: 0) do
      24.times { AiContracts::Quota.consume!(@user.id, :model) }
      assert_equal "web_quota_exceeded", assert_raises(SignflowAgent::Error) { AiContracts::Quota.consume!(@user.id, :model) }.message
      assert AiContracts::Quota.consume!(@user.id + 1, :model)
      travel 10.minutes
      assert AiContracts::Quota.consume!(@user.id, :model)
    end
  end

  test "secrets oversized input and unapproved writes fail before provider construction" do
    [ "AIza#{'x' * 35}", "sf_agent_#{'x' * 43}", "x" * 8001 ].each do |prompt|
      assert_raises(SignflowAgent::Error) { @service.message(@conversation, prompt: prompt, step: "0") }
    end
    assert_no_difference("Document.count") { assert_raises(SignflowAgent::Error) { @service.approve(@conversation) } }
  end

  test "malformed version selectors and foreign owner associations are refused" do
    [ [], {}, "0", "-1", "1 OR 1=1" ].each do |id|
      assert_no_difference("AiContractConversation.count") do
        assert_raises(SignflowAgent::Error) { @service.start(version_id: id, synthetic: "1") }
      end
    end
    other = create_user(email: "foreign-model@example.com")
    conversation = other.ai_contract_conversations.new(template_version: @template.current_version,
      public_id: SecureRandom.uuid, expires_at: 1.hour.from_now)
    assert_not conversation.valid?
    assert conversation.errors[:template_version].any?
  end
end
