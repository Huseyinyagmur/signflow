module AiContracts
  class Quota
    STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)
    LOCK = Mutex.new
    LIMITS = { starts: 5, model: 24 }.freeze

    # Conservative logical-call cap; each provider call has at most two HTTP attempts.
    def self.consume!(user_id, kind)
      LOCK.synchronize do
        key = [ user_id, kind, Time.current.to_i / 600 ]
        count = STORE.read(key).to_i
        raise SignflowAgent::Error, "web_quota_exceeded" if count >= LIMITS.fetch(kind)

        STORE.write(key, count + 1, expires_in: 10.minutes)
      end
    end
  end
end
