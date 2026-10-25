# Opt-in only: never redirects the normal SQLite suite to PostgreSQL.
if !ENV["SIGNFLOW_AGENT_TEST_DATABASE_URL"].to_s.empty?
  require "test_helper"
  require "timeout"

  class AgentConcurrencyTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    setup do
      assert_equal "PostgreSQL", ActiveRecord::Base.connection.adapter_name
      @owner = create_user(email: "race-#{SecureRandom.hex(8)}@example.com")
      template = create_template(user: @owner, content: "{{hizmet}}")
      @credential, = AgentCredential.issue!(user: @owner, label: "Concurrency", expires_at: 1.day.from_now)
      @payload = { "template_id" => template.id, "template_version_id" => template.current_version_id,
        "values" => { "hizmet" => "Concurrent demo" }, "document" => { "title" => "Concurrent draft" } }
    end

    test "two simultaneous connections with the same key commit one draft" do
      results = race([ @payload, @payload ])
      assert_equal 1, @owner.documents.count
      assert_equal 1, @owner.agent_requests.count
      assert_equal 1, results.map(&:first).uniq.size
      assert_equal [ false, true ], results.map(&:last).sort_by(&:to_s)
    end

    test "same key with different simultaneous payload conflicts" do
      changed = @payload.deep_dup
      changed["document"]["title"] = "Different draft"
      results = race([ @payload, changed ])
      assert_equal 1, @owner.documents.count
      assert_equal 1, @owner.agent_requests.count
      assert_equal 1, results.count { |result| result == :conflict }
    end

    private

    def race(payloads)
      ready, release, outcomes = Queue.new, Queue.new, Queue.new
      threads = payloads.map do |payload|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            credential = AgentCredential.find(@credential.id)
            ready << true
            release.pop
            begin
              document, replayed = Agents::CreateDraft.call(credential: credential, key: "concurrent-request-0001", payload: payload)
              outcomes << [ document.id, replayed ]
            rescue Agents::CreateDraft::Conflict
              outcomes << :conflict
            rescue StandardError => error
              outcomes << error
            end
          end
        end
      end
      Timeout.timeout(20) { threads.size.times { ready.pop } }
      threads.size.times { release << true }
      threads.each { |thread| assert thread.join(20), "Concurrency worker timed out" }
      results = threads.size.times.map { outcomes.pop }
      results.each { |result| raise result if result.is_a?(Exception) }
      results
    ensure
      threads&.each { |thread| thread.kill if thread.alive? }
    end
  end
end
