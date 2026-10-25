if !ENV["SIGNFLOW_AGENT_TEST_DATABASE_URL"].to_s.empty?
  require "test_helper"
  require "timeout"

  class StarterTemplatesConcurrencyTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    test "simultaneous owner recovery creates one set of three versions" do
      assert_equal "PostgreSQL", ActiveRecord::Base.connection.adapter_name
      owner = create_user(email: "starter-race-#{SecureRandom.hex(8)}@example.com")
      ready, release, outcomes = Queue.new, Queue.new, Queue.new
      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            user = User.find(owner.id)
            ready << true
            release.pop
            begin
              outcomes << Templates::DemoSeeder.call(user: user)
            rescue StandardError => error
              outcomes << error
            end
          end
        end
      end
      Timeout.timeout(20) { 2.times { ready.pop } }
      2.times { release << true }
      threads.each { |thread| assert thread.join(20), "Starter recovery timed out" }
      results = 2.times.map { outcomes.pop }
      results.each { |result| raise result if result.is_a?(Exception) }
      assert_equal [ 0, 3 ], results.sort
      assert_equal 3, owner.templates.count
      assert_equal 3, TemplateVersion.joins(:template).where(templates: { user_id: owner.id }).count
      assert_equal [ 1 ], owner.templates.includes(:current_version).map { |template| template.current_version.number }.uniq
    ensure
      threads&.each { |thread| thread.kill if thread.alive? }
    end
  end
end
