if !ENV["SIGNFLOW_AGENT_TEST_DATABASE_URL"].to_s.empty?
  require "test_helper"
  require "timeout"

  class AiContractConcurrencyTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    test "independent approval connections commit exactly one document and recover without memory" do
      assert_equal "PostgreSQL", ActiveRecord::Base.connection.adapter_name
      owner = create_user(email: "web-race-#{SecureRandom.hex(8)}@example.com")
      template = create_template(user: owner, content: "{{hizmet}}")
      conversation = owner.ai_contract_conversations.create!(template_version: template.current_version,
        public_id: SecureRandom.uuid, expires_at: 1.hour.from_now)
      payload = { "template_id" => template.id, "template_version_id" => template.current_version_id,
        "values" => { "hizmet" => "Concurrent synthetic demo" }, "document" => { "title" => "Web draft" } }
      ready, release, outcomes = Queue.new, Queue.new, Queue.new
      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            user = User.find(owner.id)
            ready << true
            release.pop
            begin
              document = AiContracts::CreateDraft.call(user: user, conversation_id: conversation.public_id, payload: payload)
              outcomes << document.id
            rescue StandardError => error
              outcomes << error
            end
          end
        end
      end
      Timeout.timeout(20) { 2.times { ready.pop } }
      2.times { release << true }
      threads.each { |thread| assert thread.join(20), "Concurrent approval timed out" }
      results = 2.times.map { outcomes.pop }
      results.each { |result| raise result if result.is_a?(Exception) }
      assert_equal 1, results.uniq.size
      assert_equal 1, owner.documents.count
      assert_equal results.first, conversation.reload.document_id
      AiContracts::Conversations.reset!
      document = AiContracts::Conversations.new(user: owner).approve(conversation)
      assert_equal results.first, document.id
      assert document.draft?
      assert_nil document.signing_token_digest
    ensure
      threads&.each { |thread| thread.kill if thread.alive? }
    end
  end
end
