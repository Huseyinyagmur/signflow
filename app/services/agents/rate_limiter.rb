module Agents
  # Demo-only, per-process fixed window. Eviction/restart resets budgets.
  class RateLimiter
    STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)
    LOCK = Mutex.new
    LIMITS = { read: 60, write: 10 }.freeze
    WINDOW = 60

    def self.consume(credential_id:, bucket:)
      limit = LIMITS.fetch(bucket)
      key = "agent-api:#{credential_id}:#{bucket}"
      LOCK.synchronize do
        now = Time.current.to_f
        entry = STORE.read(key)
        entry = { count: 0, reset_at: now + WINDOW } unless entry && entry[:reset_at] > now
        wait = [ (entry[:reset_at] - now).ceil, 1 ].max
        return [ false, wait ] if entry[:count] >= limit

        entry[:count] += 1
        STORE.write(key, entry, expires_in: wait)
        [ true, wait ]
      end
    end

    def self.reset!
      LOCK.synchronize { STORE.clear }
    end
  end
end
