require "test_helper"

class AgentRateLimiterTest < ActiveSupport::TestCase
  test "concurrent callers share the single process credential budget atomically" do
    Agents::RateLimiter.reset!
    outcomes = Queue.new
    threads = 20.times.map do
      Thread.new { outcomes << Agents::RateLimiter.consume(credential_id: 99, bucket: :write).first }
    end
    threads.each { |thread| assert thread.join(5) }
    assert_equal 10, 20.times.count { outcomes.pop }
  ensure
    Agents::RateLimiter.reset!
  end
end
